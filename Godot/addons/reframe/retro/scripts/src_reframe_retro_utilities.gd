extends RefCounted
class_name ReframeRetroUtilities

static func global_shader_parameters_defaults() -> void:
	# Basic globals
	global_shader_parameter_set("reframe_retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, 0)
	global_shader_parameter_set("reframe_retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, Vector2.ZERO)
	global_shader_parameter_set("reframe_retro_color_quantization_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, 0)
	global_shader_parameter_set("reframe_retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0)
	global_shader_parameter_set("reframe_retro_affine_texture_mapping_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0)
	global_shader_parameter_set("reframe_retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT,0.00001)
	global_shader_parameter_set("reframe_retro_fog_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, 0)
	global_shader_parameter_set("reframe_retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, 0)
	global_shader_parameter_set("reframe_retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2,Vector2.ZERO)
	global_shader_parameter_set("reframe_retro_fog_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, Vector2.ZERO)
	global_shader_parameter_set("reframe_retro_light_directional_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(0,1,0))
	global_shader_parameter_set("reframe_retro_light_directional_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1)
	global_shader_parameter_set("reframe_retro_light_directional_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, Color.BLACK)
	global_shader_parameter_set("reframe_retro_dithering_mode", RenderingServer.GLOBAL_VAR_TYPE_INT,0)
	global_shader_parameter_set_texture("reframe_retro_dithering_matrix_texture", null)
	global_shader_parameter_set("reframe_retro_dithering_matrix_size", RenderingServer.GLOBAL_VAR_TYPE_INT, 0)
	global_shader_parameter_set("reframe_retro_dithering_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0)


static func global_shader_parameter_set(name: String, type, value) -> void:
		if RenderingServer.global_shader_parameter_get(name) == null:
			RenderingServer.global_shader_parameter_add(name, type, value)
		RenderingServer.global_shader_parameter_set(name, value)
		
static func global_shader_parameter_set_texture(name: String, tex: Texture2D) -> void:
	# If null, use a small default texture
	# Sampler2D can not be null
	var value : Texture2D = tex
	if value == null:
		var img := Image.new()
		img.create(4, 4, false, Image.FORMAT_R8)
		img.fill(Color(0,0,0)) # white
		var default_tex := ImageTexture.new()
		default_tex.create_from_image(img)
		value = default_tex

	# Update or add the shader global
	if RenderingServer.global_shader_parameter_get(name) == null:
		RenderingServer.global_shader_parameter_add(name, RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, value)
	else:
		RenderingServer.global_shader_parameter_set(name, value)
	
