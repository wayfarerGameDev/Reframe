shader_type spatial;
render_mode unshaded, fog_disabled;

// Globals
global uniform vec2 reframe_retro_resolution;
global uniform float reframe_retro_resolution_mode;
global uniform float reframe_retro_color_quantization_depth;
global uniform float reframe_retro_dithering_strength;
global uniform float reframe_retro_pixel_jitter_strength;
global uniform vec4 reframe_retro_fog_color;
global uniform vec2 reframe_retro_fog_start_end_distance;
global uniform int reframe_retro_depth_precision;

// Locals
const float REFRAME_RETRO_DITHER_MATRIX[16] = float[]
(
    0.0,       0.25806452, 0.06451613, 0.32258065,
    0.38709677, 0.12903226, 0.45161290, 0.19354839,
    0.09677419, 0.35483871, 0.03225806, 0.29032258,
    0.48387097, 0.22580645, 0.41935484, 0.16129032
);

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, source_color;

void vertex()
{
    // Fill screen by mapping to camera
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment()
{
    // UVs
	// iUV is discrete grid position in retro resolution space
	// Snapped used to give blocky look to things like fog
  	vec2 uv = mix(SCREEN_UV, floor(SCREEN_UV * reframe_retro_resolution) / reframe_retro_resolution, clamp(reframe_retro_resolution_mode, 0.0, 1.0));
    ivec2 iuv = ivec2(SCREEN_UV * reframe_retro_resolution);

    // Vertex jitter
    // Adds a small deterministic offset per pixel
    // This is not accurate to PS1 as that's vertex based and not pixel but this is still good effect to include
    float wobble_strength = reframe_retro_pixel_jitter_strength / reframe_retro_resolution.x;
    uv += vec2(
        (fract(sin(float(iuv.x * 7 + iuv.y * 13)) * 43758.5453) - 0.5) * wobble_strength,
        (fract(sin(float(iuv.y * 17 + iuv.x * 19)) * 43758.5453) - 0.5) * wobble_strength
    );

	// UVs
	// Snapped used to give blocky look to things like fog
	// Need to be done after vertex jitter so jitter is correctly passed
	vec2 uv_snapped = floor(uv * reframe_retro_resolution) / reframe_retro_resolution;

    // Sample the sources
    vec3 color = texture(SCREEN_TEXTURE, uv).rgb;
	float depth = texture(DEPTH_TEXTURE, uv_snapped).r;

	// View
	vec3 normalized_device_coord = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(normalized_device_coord,1);
	view.xyz /= view.w; // perspective divide, giving the correct 3D position in view spac

	// Fog
	float linear_depth = -view.z;
	float fog_factor = clamp((linear_depth - reframe_retro_fog_start_end_distance.x) / (reframe_retro_fog_start_end_distance.y - reframe_retro_fog_start_end_distance.x), 0.0, 1.0);
	fog_factor = floor(fog_factor * float(reframe_retro_depth_precision)) / float(reframe_retro_depth_precision);
	color = mix(color, reframe_retro_fog_color.rgb, fog_factor * reframe_retro_fog_color.a);

    // Dithering
    int index = int(iuv.x % 4) + int(iuv.y % 4) * 4;
    float dither = REFRAME_RETRO_DITHER_MATRIX[index] / reframe_retro_color_quantization_depth * reframe_retro_dithering_strength;
    color += vec3(dither);

    // Color quantization
    color = round(color * reframe_retro_color_quantization_depth) / reframe_retro_color_quantization_depth;

    // Output final color
    ALBEDO = color;
}
