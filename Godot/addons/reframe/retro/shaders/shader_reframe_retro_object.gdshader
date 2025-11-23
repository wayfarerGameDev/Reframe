shader_type spatial;
render_mode world_vertex_coords, specular_disabled, vertex_lighting;

// Globals
global uniform vec2 reframe_retro_resolution;
global uniform float reframe_retro_vertex_jitter_strength;

//
uniform sampler2D albedo_texture: source_color, filter_nearest;

void vertex()
{
	// Input
	vec4 position = PROJECTION_MATRIX * VIEW_MATRIX * vec4(VERTEX,1);

	// Vertex wobble
	vec2 vertex_wobble_snap = reframe_retro_resolution * (1.0 - clamp(reframe_retro_vertex_jitter_strength,0,0.99));
	vec2 vertex_wobble_screen_position = round(position.xy * vertex_wobble_snap) / vertex_wobble_snap;
	POSITION = vec4(vertex_wobble_screen_position, position.zw);
}

void fragment()
{
	vec3 color = texture(albedo_texture,UV).rgb;
	ALBEDO = color;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
