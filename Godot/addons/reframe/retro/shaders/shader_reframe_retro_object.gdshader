shader_type spatial;
render_mode specular_disabled, unshaded;

// Globals
global uniform vec2 reframe_retro_resolution;
global uniform int reframe_retro_resolution_mode;
global uniform float reframe_retro_affine_texture_mapping_strength;
global uniform int reframe_retro_color_quantization_mode;
global uniform float reframe_retro_color_quantization_depth;
global uniform int reframe_retro_dithering_mode;
global uniform sampler2D reframe_retro_dithering_matrix_texture : filter_nearest;
global uniform float reframe_retro_dithering_strength;
global uniform int   reframe_retro_dithering_matrix_size;
global uniform float reframe_retro_vertex_jitter_strength;


// Locals
uniform bool billboard = false;
uniform vec2 repeat_factor = vec2(0,0);
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_disable;

// Dither matrix bassed on ps1 dither matrix
// We use texture now for more control
// const int REFRAME_RETRO_DITHER_MATRIX_PS1[16] = int[]
// (
//     0,	8,	2,	10,
//	    12,	4,	14,	6,
//	    3,	11,	1,	9,
//	    15,	7,	13,	5
// );

// Varyings
varying float clip_space_w;
varying vec2 texture_affine_mapping_uv;

void vertex()
{
	// Billboard: face camera
    if (billboard)
	{
        vec3 cam_right   = normalize(INV_VIEW_MATRIX[0].xyz);
        vec3 cam_up      = vec3(0.0, 1.0, 0.0);
        vec3 cam_forward = normalize(INV_VIEW_MATRIX[2].xyz);
        vec4 obj_position = MODEL_MATRIX[3];
    	VERTEX = obj_position.xyz + VERTEX.x * cam_right + VERTEX.y * cam_up;
	}

	// Spaces
	vec3 world_space = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 view_space = VIEW_MATRIX * vec4(world_space, 1.0);
	vec4 clip_space = PROJECTION_MATRIX * view_space;
	vec2 screen_space = (clip_space.xy / clip_space.w) * VIEWPORT_SIZE.xy;
	clip_space_w = clip_space.w;

	// Vertex Jitter
	// Ps1 accurate jitter done in clip space
	// Dependant on resolution
	clip_space.xy = (round(screen_space / (reframe_retro_vertex_jitter_strength)) * reframe_retro_vertex_jitter_strength / VIEWPORT_SIZE.xy) * clip_space.w;
	POSITION = clip_space;

	// Vertex Jitter
	// Done in view_space, not authentic to ps1 but more stylized
	// Not dependant on resolution
	// vec3 snapped_pos = floor(view_space.xyz / (reframe_retro_vertex_jitter_strength * 0.01)) * reframe_retro_vertex_jitter_strength * 0.01;
	// vec3 jitter_offset = snapped_pos - view_space.xyz;
	// VERTEX += (inverse(MODEL_MATRIX) * vec4(jitter_offset * view_space.z, 0.0)).xyz * clip_space.w;

	// Affine texture mapping
	// PS1 affine uses clip-space W
	texture_affine_mapping_uv = UV * clip_space_w;
}

void fragment()
{
	// UV
	vec2 uv = UV;

    // Repeat texture
	if (repeat_factor.x > 0.0 || repeat_factor.y > 0.0)
	{
   		uv *= repeat_factor;
   		uv = fract(uv);
	}

	// Affine texture mapping
	// PS1 affine uses clip-space W
	// Undo perspective UVs
	uv = mix(uv, texture_affine_mapping_uv / clip_space_w, reframe_retro_affine_texture_mapping_strength);

	// iUVs
	// iUV is discrete grid position in retro resolution space, snapped to give blocky look
	// Need to be calculated after above steps
	// Multipled by resolution to keep it same look as post-process version
	ivec2 iuv = ivec2(uv);
	iuv = ivec2(uv * reframe_retro_resolution);

	// Sample the sources
    vec3 color = texture(albedo_texture, uv).rgb;
	// float depth = texture(DEPTH_TEXTURE, uv_snapped).r;

	// Dithering (Hard coded matrix)
	// PS1 style: Scales with quantization step
	// if (reframe_retro_dithering_mode == 2.0)
	// {
    //	int index = int(int(uv.x) % 4) + int(int(uv.y) % 4) * 4;
    //	float dither = float(REFRAME_RETRO_DITHER_MATRIX_PS1[index]) / reframe_retro_color_quantization_depth * reframe_retro_dithering_strength * 0.1;
    //	color = color + vec3(dither);
	// }

	// Dithiring (Texutre based)
	// PS1 style: center around zero (produce values from −X to +X, with equal distribution)
	// scales with quantization step
	if (reframe_retro_dithering_mode == 1)
	{
    	int size = reframe_retro_dithering_matrix_size;
    	ivec2 pos = ivec2(iuv.x % size, iuv.y % size);
		float max_value = float(size * size - 1);
    	float sample = texture(reframe_retro_dithering_matrix_texture, (vec2(pos) + 0.5) / float(size)).r * max_value;
        float dither = ((sample / max_value) - 0.5) * 1.0 / (reframe_retro_color_quantization_depth) * reframe_retro_dithering_strength;
    	color = color + vec3(dither);
	}

	// Color quantization
	if (reframe_retro_color_quantization_mode == 1)
    	color = (round(color * reframe_retro_color_quantization_depth) / reframe_retro_color_quantization_depth);


    // Sample the texture
    ALBEDO = color;
}

void light()
{
	DIFFUSE_LIGHT = vec3(1);
	SPECULAR_LIGHT = vec3(0);
}

