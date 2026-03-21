shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, depth_draw_never;

// Globals
global uniform int retro_resolution_mode;
global uniform vec2 retro_resolution;
global uniform int retro_color_quantization_mode;
global uniform float retro_color_quantization_depth;
global uniform bool retro_color_palette_enabled;
global uniform float retro_color_palette_contrast;
global uniform float retro_color_palette_brightness;
global uniform sampler2D retro_color_palette_texture : source_color, filter_nearest;
global uniform int retro_dithering_mode;
global uniform sampler2D retro_dithering_matrix_texture : source_color, filter_nearest;
global uniform float retro_dithering_strength;
global uniform int   retro_dithering_matrix_size;
global uniform int retro_fog_mode;
global uniform vec4  retro_fog_color;
global uniform vec2  retro_fog_start_end_distance;
global uniform int retro_fog_depth_precision;
global uniform float retro_crt_curvature_strength;
global uniform float retro_crt_chromatic_aberration_strength;
global uniform float retro_crt_scanline_scale;
global uniform float retro_crt_scanline_intensity;
global uniform float retro_crt_vignette_radius;
global uniform float retro_crt_vignette_softness;
global uniform float retro_vhs_tracking_strength;
global uniform float retro_vhs_tape_noise_intensity;
global uniform float retro_vhs_chroma_bleeding_strength;
global uniform float retro_vhs_tape_dropout_intensity;
global uniform float retro_vhs_signal_ringing_strength;

// Screen and Depth buffers passed in by Godot's post-processing system
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, filter_nearest;

void vertex()
{
	// Fill screen by mapping to camera
	// Bypass standard 3D transform math to force the quad's vertices directly 
	// to the edges of the clip space (-1 to 1) so it perfectly covers the camera lens.
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment()
{
	// UVs: with resolution
	// SCREEN_UV gives us a normalized 0.0 to 1.0 coordinate across the monitor.
	vec2 uv = SCREEN_UV;
	
	// Aspect
	// We calculate aspect ratio so our CRT curvature stretches uniformly 
	// rather than looking squished on widescreen monitors.
	float aspect = retro_resolution.x / retro_resolution.y;
	
	// VHS (Tracking Wobble)
	// Simulates the horizontal "tearing" and jitter found at the bottom of 
	// poor quality VHS tapes (Head Switching Noise).
	if (retro_vhs_tracking_strength > 0.0)
	{
		// Create a "jitter" using high-frequency sine waves.
		// We use a combination of TIME and uv.y to make it look erratic.
		float wobble_noise = sin(uv.y * 100.0 + TIME * 20.0) * 0.002;
		
		// Create a mask to only affect the bottom of the screen.
		// Using a power function (pow) makes the wobble get exponentially 
		// stronger as we reach the very bottom edge.
		float wobble_mask = pow(uv.y, 10.0) * retro_vhs_tracking_strength;
		
		// Shift the horizontal UV coordinate.
		uv.x += wobble_noise * wobble_mask;
	}
	
	// CRT (Curvature)
	float crt_curvature_mask;
	{
		// 1. Shift UVs so 0,0 is the center of the screen (range -1.0 to 1.0)
		// 2. Calculate how hard the screen pulls away from the viewer.
		// 3. Offset grows exponentially the further we get from the center.
		// 4. Map the UVs back to the standard 0.0 to 1.0 space.
		vec2 centered_uv = uv * 2.0 - 1.0;
		vec2 curvature_ratio = vec2((retro_crt_curvature_strength * 0.1) / aspect, retro_crt_curvature_strength * 0.1);
		vec2 offset = abs(centered_uv.yx) * curvature_ratio;
		uv = centered_uv + centered_uv * offset * offset;
		uv = uv * 0.5 + 0.5;
	
		// Discard pixels outside the curved screen to avoid stretched edge artifacts
		// Creates a hard black mask to hide the stretched pixels outside the "glass."
		crt_curvature_mask = step(0.0, uv.x) * step(uv.x, 1.0) * step(0.0, uv.y) * step(uv.y, 1.0);
	}
		
	// Resolution
	// iUV is snapped UVs
	// If we are in post-processing mode (Mode 1), we forcibly "snap" the smooth 
	// monitor UVs into a chunky grid defined by our retro_resolution.
	if (retro_resolution_mode == 1)
		uv = floor((uv * retro_resolution)) / retro_resolution;
		
	// iuv gives us the absolute integer pixel coordinate (e.g., pixel 140x, 120y)
	// We use this later for pixel-perfect effects like dithering arrays.
	ivec2 iuv = ivec2(uv * retro_resolution);

	// Sample the sources
	// Grab the depth buffer value for our 3D effects (Fog).
	float depth = texture(DEPTH_TEXTURE, uv).r;
	vec3 color; // Sample this later so we can do chromatic aberration
	
	// CRT Chromatic Aberration
	{
		// Old cathode ray tubes fired separate Red, Green, and Blue electron beams.
		// We simulate edge misalignment by sampling the screen three separate times, 
		// physically pushing the Red and Blue UV reads outward from the center.
		vec2 ca_offset = (uv - 0.5) * retro_crt_chromatic_aberration_strength * 0.01;
		float crt_r = texture(SCREEN_TEXTURE, uv - ca_offset).r;
		float crt_g = texture(SCREEN_TEXTURE, uv).g;
		float crt_b = texture(SCREEN_TEXTURE, uv + ca_offset).b;
		color = vec3(crt_r, crt_g, crt_b);
	}
	
	// VHS (Chroma Bleeding)
	// Analog formats had low bandwidth for color but high bandwidth for brightness.
	// We simulate this by stepping into the YIQ color space (used by NTSC TVs), 
	// shifting the color channels horizontally, and recombining with original brightness.
	if (retro_vhs_chroma_bleeding_strength > 0.0)
	{
		// Calculate the smear distance relative to our chunky retro resolution.
		float bleed_offset = (retro_vhs_chroma_bleeding_strength * 3.0) / retro_resolution.x; 
		
		// Grab a "smeared" color sample from slightly to the left.
		vec3 color_shifted = texture(SCREEN_TEXTURE, uv - vec2(bleed_offset, 0.0)).rgb;
		
		// Extract the Luma (Brightness) from the ORIGINAL, sharp pixel.
		float sharp_luma = dot(color.rgb, vec3(0.299, 0.587, 0.114));
		
		// Extract the Chroma (Color) from the SHIFTED pixel.
		float smeared_i = dot(color_shifted, vec3(0.596, -0.275, -0.321));
		float smeared_q = dot(color_shifted, vec3(0.212, -0.523, 0.311));
		
		// Recombine the sharp lighting with the smeared color in YIQ space.
		vec3 yiq = vec3(sharp_luma, smeared_i, smeared_q);
		
		// Convert the YIQ signal back into standard RGB for the monitor.
		color.r = dot(yiq, vec3(1.0, 0.956, 0.621));
		color.g = dot(yiq, vec3(1.0, -0.272, -0.647));
		color.b = dot(yiq, vec3(1.0, -1.107, 1.704));
	}

	// VHS (Signal Ringing)
	// Simulates the electrical "overshoot" or ghosting seen on high-contrast edges.
	// This creates a faint, blurry echo of the image shifted slightly to the right.
	if (retro_vhs_signal_ringing_strength > 0.0)
	{
		// Define the offset for the "ghost" image.
		// We shift to the left (uv - offset) so the ghost appears to the right of the objects.
		float ringing_offset = 1.5 / retro_resolution.x;
		
		// Sample the screen again at the offset.
		vec3 ringing_sample = texture(SCREEN_TEXTURE, uv - vec2(ringing_offset, 0.0)).rgb;
		
		// Extract the high-frequency details (the edges).
		// We subtract the current color from the shifted sample to find where the contrast jumps.
		vec3 ringing_diff = (ringing_sample - color.rgb);
		
		// Apply the ghosting back onto the original image.
		// We multiply by the strength slider to control the intensity of the halo.
		color.rgb += ringing_diff * (retro_vhs_signal_ringing_strength * 0.3);
		
		// Add a very slight darkening on the opposite side to mimic "undershoot."
		vec3 undershoot_sample = texture(SCREEN_TEXTURE, uv + vec2(ringing_offset * 0.5, 0.0)).rgb;
		color.rgb -= (undershoot_sample - color.rgb) * (retro_vhs_signal_ringing_strength * 0.1);
	}
	
	// View
	// Rebuild the actual 3D world position of the pixel by feeding the 2D depth 
	// buffer backwards through the camera's Inverse Projection Matrix.
	vec3 normalized_device_coord = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(normalized_device_coord,1);
	view.xyz /= view.w; // perspective divide, giving the correct 3D position in view space

	// Fog
	// Depth precision gives banding look to give PS1 style
	if (retro_fog_mode == 3)
	{
		// Calculate a smooth 0.0 to 1.0 blend factor based on camera distance.
		float fog_range = max(retro_fog_start_end_distance.y - retro_fog_start_end_distance.x, 0.001);
		float fog_factor = clamp((-view.z - retro_fog_start_end_distance.x) / fog_range, 0.0, 1.0);
		
		// Artificially "crush" the fog gradient into harsh bands based on depth precision.
		fog_factor = floor(fog_factor * float(retro_fog_depth_precision)) / float(retro_fog_depth_precision);
		
		// Blend the fog color over the game color.
		color = mix(color, retro_fog_color.rgb, fog_factor * retro_fog_color.a);
	}

	// Dithiring (Texutre based)
	// PS1 style: center around zero (produce values from −X to +X, with equal distribution)
	// scales with quantization step to hide banding caused by low color depth.
	if (retro_dithering_mode == 2)
	{
		int size = retro_dithering_matrix_size;
		
		// Find exactly which pixel inside the matrix we are looking at.
		ivec2 pos = ivec2(iuv.x % size, iuv.y % size);
		float max_value = float(size * size - 1);
		
		// Sample the matrix texture, centered (+0.5) to avoid sampling borders.
		float sample = texture(retro_dithering_matrix_texture, (vec2(pos) + 0.5) / float(size)).r * max_value;
		
		// Remap the 0.0 -> 1.0 sample into a -X -> +X threshold bridging the quantization steps.
		float dither = ((sample / max_value) - 0.5) * 1.0 / (retro_color_quantization_depth) * retro_dithering_strength;
		color = color + vec3(dither);
	}

	// Color quantization
	// Reduces the millions of modern RGB colors down to a limited retro palette.
	// Multiplying, rounding, and dividing forces colors into rigid mathematical steps.
	if (retro_color_quantization_mode == 2)
		color = (round(color * retro_color_quantization_depth) / retro_color_quantization_depth);
		
	// Palette Mapping
	// Maps the screen's grayscale brightness (Luma) to a 1D gradient texture.
	if (retro_color_palette_enabled)
	{
		float pal_size = float(textureSize(retro_color_palette_texture, 0).x);
			
		// Luma
		// Calculate base brightness + user offset (brightness)
		// Apply Contrast (Now works with positive values!)
		// Normalize luminance to ensures fragment colors align strictly with palette indices to eliminate sub-texel interpolation artifacts.
		float luma = dot(color.rgb, vec3(0.299, 0.587, 0.114)) + retro_color_palette_brightness;
		luma = clamp((luma - 0.5) * retro_color_palette_contrast + 0.5, 0.0, 1.0);
		luma = floor(luma * (pal_size - 1.0) + 0.5) / (pal_size - 1.0);
		
		// Read the final color from the 1D palette texture.
		color.rgb = texture(retro_color_palette_texture, vec2(luma, 0.5)).rgb;
	}
	
	// VHS (Tape Noise / Snow)
	// Simulates the grainy, flickering static caused by magnetic interference.
	if (retro_vhs_tape_noise_intensity > 0.0)
	{
		// Generate high-frequency pseudo-random noise.
		// Adding TIME ensures the static flickers every frame.
		float noise_seed = dot(uv + vec2(0.0, TIME), vec2(12.9898, 78.233));
		float noise_val = fract(sin(noise_seed) * 43758.5453);
		
		// We use a "Screen" blend logic. 
		// As the intensity slider goes up, the noise becomes thicker and more opaque.
		// At 1.0 intensity, it will almost entirely mask the game image with white/gray static.
		vec3 snow = vec3(noise_val);
		
		// Blend the snow over the game color.
		// We use a mix factor that scales aggressively with the slider.
		float snow_strength = retro_vhs_tape_noise_intensity * 0.8 * 0.1;
		color.rgb = mix(color.rgb, snow, snow_strength * noise_val);
		
		// Boost the brightness of the noise at high levels to mimic signal gain.
		color.rgb += noise_val * retro_vhs_tape_noise_intensity * 0.2 * 0.1;
	}
	
	// VHS (Tape Dropouts)
	// Simulates physical damage, dust, or creases on the magnetic tape.
	if (retro_vhs_tape_dropout_intensity > 0.0)
	{
		// Group the noise into chunky horizontal rows based on retro resolution.
		// This prevents microscopic sub-pixel lines that your monitor struggles to render.
		float row_id = floor(uv.y * (retro_resolution.y * 0.75)); 
		
		// Snap the time to 24 fps. 
		// Holding the crease on screen slightly longer makes low-intensity values visible.
		float time_step = floor(TIME * 24.0);
		
		// Generate pseudo-random noise per row and time step.
		float dropout_noise = fract(sin(dot(vec2(row_id, time_step), vec2(12.9898, 78.233))) * 43758.5453);
		
		// Set the threshold. 
		// At intensity 0.0, it's 1.0 (impossible). 
		// We multiply by 0.15 so it dips into visible ranges much faster.
		float dropout_threshold = 1.0 - (retro_vhs_tape_dropout_intensity * 0.15);
		float dropout_mask = step(dropout_threshold, dropout_noise);
		
		// Determine if the streak should be bright white or dark black.
		float is_white = step(0.5, fract(sin(dot(vec2(row_id, time_step), vec2(39.346, 11.135))) * 43758.5453));
		vec3 streak_color = vec3(is_white);
		
		// Scale the opacity based on the slider.
		// At low values, the creases are faint and transparent. At higher values, they are stark.
		float blend_strength = clamp(retro_vhs_tape_dropout_intensity * 2.0, 0.0, 0.85);
		
		// Blend heavily over the game image.
		color = mix(color, streak_color, dropout_mask * blend_strength); 
	}
	
	// CRT (Scanlines)
	{
		float scanline_mask = 1.0;
		
		// Mode 0: Internal Resolution
		// In this mode, the viewport itself is tiny (e.g., 240p).
		// We lack the high-resolution "overhead" to draw sub-pixel lines, 
		// so we use a pixel-perfect checkerboard pattern to darken alternating rows.
		if (retro_resolution_mode == 0) 
		{
			float pixel_row = floor(uv.y * retro_resolution.y);
			scanline_mask = mix(1.0, 0.5, mod(pixel_row, 2.0));
		} 
		// Mode 1: Post-processing Resolution
		// In this mode, we have a high-resolution screen (e.g., 1080p) to work with.
		// We use FRAGCOORD to draw sharp, sub-pixel lines that align perfectly 
		// with the seams of the chunky retro pixels for a more authentic CRT look.
		else 
		{
			float screen_y = FRAGCOORD.y;
			float physical_pixels_per_retro = VIEWPORT_SIZE.y / retro_resolution.y;
			float scanline_wave = sin((screen_y / physical_pixels_per_retro) * PI * 2.0);
			scanline_mask = pow(scanline_wave * 0.5 + 0.5, 2.0);
		}
		
		// Apply intensity and scale
		// This combines the calculated mask with the user-defined strength parameters
		float final_intensity = retro_crt_scanline_intensity * retro_crt_scanline_scale;
		color.rgb *= mix(1.0, scanline_mask, final_intensity);
	}
	
	// CRT (Vignette)
	// Darkens the corners of the screen based on distance from the center (0.5, 0.5)
	// Uses smoothstep for a natural, analog lens falloff.
	float dist = distance(uv, vec2(0.5));
	float vignette = smoothstep(retro_crt_vignette_radius, retro_crt_vignette_radius + retro_crt_vignette_softness, dist);
	color.rgb = mix(color.rgb, vec3(0.0), vignette);
	
	// Output
	ALBEDO = color * crt_curvature_mask;
}

