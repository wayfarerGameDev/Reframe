shader_type spatial;
render_mode unshaded, fog_disabled;

// Globals
global uniform int reframe_retro_resolution_mode;
global uniform vec2 reframe_retro_resolution;
global uniform int reframe_retro_color_quantization_mode;
global uniform float reframe_retro_color_quantization_depth;
global uniform int reframe_retro_dithering_mode;
global uniform sampler2D reframe_retro_dithering_matrix_texture : filter_nearest;
global uniform float reframe_retro_dithering_strength;
global uniform int   reframe_retro_dithering_matrix_size;
global uniform int reframe_retro_fog_mode;
global uniform vec4  reframe_retro_fog_color;
global uniform vec2  reframe_retro_fog_start_end_distance;
global uniform int reframe_retro_fog_depth_precision;

// Locals
// Dither matrix bassed on ps1 dither matrix
// We use texture now for more control
// const int REFRAME_RETRO_DITHER_MATRIX_PS1[16] = int[]
// (
//     0,	8,	2,	10,
//	    12,	4,	14,	6,
//	    3,	11,	1,	9,
//	    15,	7,	13,	5
// );

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform sampler2D DEPTH_TEXTURE: hint_depth_texture, source_color;

void vertex()
{
    // Fill screen by mapping to camera
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment()
{
    // UVs: with resolution
	// iUV is snapped UVs
  	vec2 uv = SCREEN_UV;
	if (reframe_retro_resolution_mode == 1)
		uv = floor((uv * reframe_retro_resolution)) / reframe_retro_resolution;
	ivec2 iuv = ivec2(uv * reframe_retro_resolution);

    // Sample the sources
    vec3 color = texture(SCREEN_TEXTURE, uv).rgb;
	float depth = texture(DEPTH_TEXTURE, uv).r;

	// View
	vec3 normalized_device_coord = vec3(uv * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(normalized_device_coord,1);
	view.xyz /= view.w; // perspective divide, giving the correct 3D position in view spac

	// Fog
	// Depth precision gives banding look to give PS1 style
	if (reframe_retro_fog_mode == 2)
	{
		float fog_factor = clamp((-view.z - reframe_retro_fog_start_end_distance.x) / (reframe_retro_fog_start_end_distance.y - reframe_retro_fog_start_end_distance.x), 0.0, 1.0);
		fog_factor = floor(fog_factor * float(reframe_retro_fog_depth_precision)) / float(reframe_retro_fog_depth_precision);
		color = mix(color, reframe_retro_fog_color.rgb, fog_factor * reframe_retro_fog_color.a);
	}

	// Dithering (Hard coded matrix)
	// PS1 style: Scales with quantization step
	// if (reframe_retro_dithering_mode == 2.0)
	// {
    //	int index = int(iuv.x % 4) + int(iuv.y % 4) * 4;
    //	float dither = float(REFRAME_RETRO_DITHER_MATRIX_PS1[index]) / reframe_retro_color_quantization_depth * reframe_retro_dithering_strength * 0.1;
    //	color = color + vec3(dither);
	// }

	// Dithiring (Texutre based)
	// PS1 style: center around zero (produce values from −X to +X, with equal distribution)
	// scales with quantization step
	if (reframe_retro_dithering_mode == 2)
	{
    	int size = reframe_retro_dithering_matrix_size;
    	ivec2 pos = ivec2(iuv.x % size, iuv.y % size);
		float max_value = float(size * size - 1);
    	float sample = texture(reframe_retro_dithering_matrix_texture, (vec2(pos) + 0.5) / float(size)).r * max_value;
        float dither = ((sample / max_value) - 0.5) * 1.0 / (reframe_retro_color_quantization_depth) * reframe_retro_dithering_strength;
    	color = color + vec3(dither);
	}

    // Color quantization
	if (reframe_retro_color_quantization_mode == 2)
    	color = (round(color * reframe_retro_color_quantization_depth) / reframe_retro_color_quantization_depth);

    // Output
    ALBEDO = color;
}

