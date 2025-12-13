shader_type spatial;
render_mode cull_back;

// Cascades
uniform sampler2D cascade_heightmap_0 : repeat_enable;
uniform sampler2D cascade_heightmap_1 : repeat_enable;
uniform sampler2D cascade_heightmap_2 : repeat_enable;
uniform sampler2D cascade_heightmap_3 : repeat_enable;
uniform vec4 cascade_world_0;
uniform vec4 cascade_world_1;
uniform vec4 cascade_world_2;
uniform vec4 cascade_world_3;

// Base
uniform vec4 base_world;

void vertex()
{
	// Wold position
	vec3 world_pos = floor(MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Cascades
	vec2 cascade_uv_0 = (world_pos.xz - cascade_world_0.xy) / cascade_world_0.w;
	vec4 cascade_sample_0 = texture(cascade_heightmap_0, cascade_uv_0) * cascade_world_0.z;
	vec2 cascade_uv_1 = (world_pos.xz - cascade_world_1.xy) / cascade_world_1.w;
	vec4 cascade_sample_1 = texture(cascade_heightmap_1, cascade_uv_1) * cascade_world_1.z;
	vec2 cascade_uv_2 = (world_pos.xz - cascade_world_2.xy) / cascade_world_2.w;
	vec4 cascade_sample_2 = texture(cascade_heightmap_2, cascade_uv_2) * cascade_world_2.z;
	vec2 cascade_uv_3 = (world_pos.xz - cascade_world_3.xy) / cascade_world_3.w;
	vec4 cascade_sample_3 = texture(cascade_heightmap_3, cascade_uv_3) * cascade_world_3.z;
	VERTEX.y += cascade_sample_0.g + cascade_sample_1.g + cascade_sample_2.g + cascade_sample_3.g;
}
