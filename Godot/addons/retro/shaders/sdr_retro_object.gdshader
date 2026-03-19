shader_type spatial;
render_mode specular_disabled, unshaded, depth_draw_always;

#define TEXTURE_FILTERING_N64 0
#define TEXTURE_FILTERING_PSX 1
#define TEXTURE_FILTERING TEXTURE_FILTERING_PSX

// Globals
global uniform vec2 retro_resolution;
global uniform float retro_texture_affine_mapping_strength;
global uniform float retro_texture_masking_threshold;
global uniform int retro_color_quantization_mode;
global uniform float retro_color_quantization_depth;
global uniform int retro_dithering_mode;
global uniform sampler2D retro_dithering_matrix_texture : filter_nearest;
global uniform float retro_dithering_strength;
global uniform int retro_dithering_matrix_size;
global uniform int retro_vertex_jitter_mode;
global uniform float retro_vertex_jitter_strength;
global uniform float retro_vertex_z_fighting_reduction;
global uniform int retro_fog_mode;
global uniform vec4 retro_fog_color;
global uniform vec2 retro_fog_start_end_distance;
global uniform int retro_fog_depth_precision;
global uniform int retro_light_mode;
global uniform vec3 retro_light_directional_direction;
global uniform float retro_light_directional_intensity;
global uniform vec4 retro_light_directional_color;

// Locals
#if TEXTURE_FILTERING == TEXTURE_FILTERING_N64
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_disable;
#endif
#if TEXTURE_FILTERING == TEXTURE_FILTERING_PSX
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_disable;
#endif
uniform int billboard_mode : hint_enum("Disabled,Y,XYZ") = 0;
uniform float repeat_factor = 0;

// Dither matrix bassed on ps1 dither matrix
// We use texture now for more control
// const int retro_DITHER_MATRIX_PS1[16] = int[]
// (
//     0,	8,	2,	10,
//	    12,	4,	14,	6,
//	    3,	11,	1,	9,
//	    15,	7,	13,	5
// );

// Varyings
varying float _clip_space_w;
varying vec2 _texture_affine_mapping_uv;
varying float _fog_factor;
varying vec3 _local_normal;

void vertex()
{
	// Billboard: face camera
    if (billboard_mode != 0)
	{
        vec3 cam_right   = normalize(INV_VIEW_MATRIX[0].xyz);
		vec3 cam_up = mix(vec3(0.0, 1.0, 0.0), normalize(INV_VIEW_MATRIX[1].xyz), float(billboard_mode == 2));
        vec4 obj_position = MODEL_MATRIX[3];
    	VERTEX = obj_position.xyz + VERTEX.x * cam_right + VERTEX.y * cam_up;
	}

	// Spaces
	vec3 world_space = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec4 view_space = VIEW_MATRIX * vec4(world_space, 1.0);
	vec4 clip_space = PROJECTION_MATRIX * view_space;
	vec2 screen_space = (clip_space.xy / clip_space.w) * VIEWPORT_SIZE.xy;
	_clip_space_w = max(clip_space.w, 0.001);


	// Vertex Jitter
	// Ps1 accurate jitter done in clip space
	// Dependant on resolution
	if (retro_vertex_jitter_mode == 0)
	{
		vec2 snap_res = VIEWPORT_SIZE.xy / max(retro_vertex_jitter_strength, 0.001);
		clip_space.xy = floor(clip_space.xy / clip_space.w * snap_res) / snap_res * clip_space.w;
		POSITION = clip_space;
	}
	
	// Vertex Jitter
	// Done in view_space, not authentic to ps1 but more stylized
	// Not dependant on resolution
	if (retro_vertex_jitter_mode == 1)
	{
		float step_size = retro_vertex_jitter_strength * 0.0025; 
		POSITION = PROJECTION_MATRIX * vec4(floor(view_space.xy / step_size) * step_size, view_space.z, view_space.w);
	}
	
	// Pass normal to fragment shader for Pixel mode
	_local_normal = NORMAL;
	
	// Light (Directional) (Vertex)
	// PS1 Per-Vertex Shading (Gouraud shading)
	// Use the normal perspective-corrected lighting
	if (retro_light_mode == 1)
	{
		float light_dot = clamp(dot(NORMAL,normalize(retro_light_directional_direction)),0,1);
		vec4 light = retro_light_directional_color + retro_light_directional_intensity * light_dot;
		vec3 light_factor = clamp(light.rgb,vec3(0),vec3(1));
		COLOR.rgb = light_factor;
		// COLOR.rgb = light_factor * clip_space_w;
	}
	// Light default
	else
		COLOR.rgb = vec3(1.0);
	
	// Affine texture mapping
	// PS1 affine uses clip-space W
	// Must be applied things like lighting and fog
	_texture_affine_mapping_uv = UV * _clip_space_w;
		
	// Fog (Vertex)
	// View space Z is negative, flip it to get distance from camera
	if (retro_fog_mode == 1)
	{
		float depth = -view_space.z; 
		float fog_range = max(retro_fog_start_end_distance.y - retro_fog_start_end_distance.x, 0.001);
		_fog_factor = clamp((depth - retro_fog_start_end_distance.x) / fog_range, 0.0, 1.0);
	}
	else _fog_factor = 0.0;
	
	// Z-Fighting (PSX)
	// reduction = 1.0 -> Modern stable depth
	// reduction = 0.5 -> High-end PSX : Occasional shimmering on wall edges and floor joins.
	// reduction = 0.0 -> Authentic PSX : Objects will flicker through each other if they are even remotely close. This is the "Software Rendering" look..
	// Lowering the 'z_precision' forces the polygons to snap to the same depth layers
	float z_precision = mix(100.0, 10000.0, retro_vertex_z_fighting_reduction);
	POSITION.z = floor(POSITION.z * z_precision) / z_precision;
	// Apply a tiny 'Z-prepass' bias only when reduction is high to prevent self-clipping
	POSITION.z += (0.00001 * retro_vertex_z_fighting_reduction);
}

void fragment()
{
	// UV
	vec2 uv = UV;

	// Affine texture mapping
	// PS1 affine uses clip-space W
	// Undo perspective UVs
	uv = mix(uv, _texture_affine_mapping_uv / _clip_space_w, retro_texture_affine_mapping_strength);
	
	// Lighting (Base)
	// Use the normal perspective-corrected lighting
	// vec3 vertex_color = mix(COLOR.rgb, COLOR.rgb / clip_space_w,  retro_texture_affine_mapping_strength);
	vec3 vertex_color = COLOR.rgb;
	
	// Light (Directional) (Pixel)
	// N64/PS2 Phong Shading
	if (retro_light_mode == 2)
	{
		float light_dot = clamp(dot(normalize(_local_normal), normalize(retro_light_directional_direction)), 0.0, 1.0);
		vec4 light = retro_light_directional_color + retro_light_directional_intensity * light_dot;
		vertex_color = clamp(light.rgb, vec3(0.0), vec3(1.0));
	}
	
	// Repeat texture
	if (repeat_factor > 0.0)
	{
   		uv *= repeat_factor;
   		uv = fract(uv);
	}
	
	// iUVs
	// iUV is discrete grid position in retro resolution space, snapped to give blocky look
	// Need to be calculated after above steps
	// Multipled by resolution to keep it same look as post-process version
	ivec2 iuv = ivec2(uv * retro_resolution);

	// Albedo
	vec4 albedo_sample = texture(albedo_texture, uv);
	
	// Texture Masking / Alpha testing
	// 1-Bit Alpha /Punch-Through
	if (albedo_sample.a < retro_texture_masking_threshold)
		discard;
	
	// Color
	// Apply lighting and vertex color using the data we already sampled
	vec3 color = albedo_sample.rgb * vertex_color;
	
	// Fog (Vertex)
	// Fog factor calculated in Vertex shader
	// Mix color with fog color based on distance
	// BEFORE quantization so the fog gets effected
	if (retro_fog_mode == 1) 
		color = mix(color, retro_fog_color.rgb, _fog_factor * retro_fog_color.a);
	
	// Fog (Pixel)
	// Mix color with fog color based on distance
	// BEFORE quantization so the fog gets effected
	else if (retro_fog_mode == 2) 
	{
		// Note: We use VERTEX.z because in Godot's spatial fragment shader, VERTEX is view-space
		float fog_range = max(retro_fog_start_end_distance.y - retro_fog_start_end_distance.x, 0.001);
		float fog_factor_pixel = clamp((-VERTEX.z - retro_fog_start_end_distance.x) / fog_range, 0.0, 1.0);
		fog_factor_pixel = floor(fog_factor_pixel * float(retro_fog_depth_precision)) / float(retro_fog_depth_precision);
		color = mix(color, retro_fog_color.rgb, fog_factor_pixel * retro_fog_color.a);
	}
		
	// Dithering (Hard coded matrix)
	// PS1 style: Scales with quantization step
	// if (retro_dithering_mode == 2.0)
	// {
    //	int index = int(int(uv.x) % 4) + int(int(uv.y) % 4) * 4;
    //	float dither = float(retro_DITHER_MATRIX_PS1[index]) / retro_color_quantization_depth * retro_dithering_strength * 0.1;
    //	color = color + vec3(dither);
	// }

	// Dithiring (Texutre based)
	// PS1 style: center around zero (produce values from −X to +X, with equal distribution)
	// scales with quantization step
	if (retro_dithering_mode == 1)
	{
    	int size = retro_dithering_matrix_size;
    	ivec2 pos = ivec2(iuv.x % size, iuv.y % size);
		float max_value = float(size * size - 1);
    	float sample = texture(retro_dithering_matrix_texture, (vec2(pos) + 0.5) / float(size)).r * max_value;
        float dither = ((sample / max_value) - 0.5) * 1.0 / (retro_color_quantization_depth) * retro_dithering_strength;
    	color = color + vec3(dither);
	}

	// Color quantization
	if (retro_color_quantization_mode == 1)
    	color = (round(color * retro_color_quantization_depth) / retro_color_quantization_depth);

    // Sample the texture
    ALBEDO = color;
}

void light()
{
	// DIFFUSE_LIGHT = vec3(1);
	// SPECULAR_LIGHT = vec3(0);
}
