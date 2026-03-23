extends RefCounted
class_name RetroUtilities

static func global_shader_parameters_set_defaults() -> void:
	global_shader_parameters_set_resolution(0, Vector2.ZERO)
	global_shader_parameters_set_сolor_palette(null, 0, 1.0, 1.0)
	global_shader_parameters_set_color_quantization(0, 0.0)
	global_shader_parameters_set_texture_behavior(0.0, 0.5, 0.0)
	global_shader_parameters_set_vertex_jitter(1, 0.00001, 0, Vector2.ZERO, Vector2i.ZERO)
	global_shader_parameters_set_fog(0, Color.BLACK, Vector2.ZERO, 0)
	global_shader_parameters_set_lighting(0, Vector3(0, 1, 0), 1.0, Color.BLACK)
	global_shader_parameters_set_dithering(0, null, 0.0)
	global_shader_parameters_set_crt(false, 0.0, 5.0, 1.0, 0.5, 0.35, 0.4)
	global_shader_parameters_set_vhs(false, 0.15, 0.1, 0.4, 0.15, 0.3)
	
static func global_shader_parameters_set_by_resource(resource: RetroSettingsResource, window_size: Vector2i) -> void:
	# Validate
	if (resource == null):
		global_shader_parameters_set_defaults()
		return
		
	global_shader_parameters_set_resolution(resource.resolution_mode, resource.resolution)
	global_shader_parameters_set_сolor_palette(resource.color_palette_texture, resource.color_palette_strength, resource.color_palette_contrast, resource.color_palette_brightness)
	global_shader_parameters_set_color_quantization(resource.color_quantization_mode, resource.color_quantization_depth)
	global_shader_parameters_set_texture_behavior(resource.texture_affine_mapping_strength, resource.texture_masking_threshold, resource.vertex_z_fighting_reduction)
	global_shader_parameters_set_vertex_jitter(resource.vertex_jitter_mode, resource.vertex_jitter_strength, resource.resolution_mode, resource.resolution, window_size)
	global_shader_parameters_set_fog(resource.fog_mode, resource.fog_color, resource.fog_start_end_distance, resource.fog_depth_precision)
	global_shader_parameters_set_lighting(resource.light_mode, resource.light_directional_direction, resource.light_directional_intensity, resource.light_directional_color)
	global_shader_parameters_set_dithering(resource.dithering_mode, resource.dithering_matrix_texture, resource.dithering_strength)
	global_shader_parameters_set_crt(resource.crt_enabled, resource.crt_curvature_strength,resource.crt_chromatic_aberration_strength,resource.crt_scanline_scale,resource.crt_scanline_intensity,resource.crt_vignette_radius,resource.crt_vignette_softness)
	global_shader_parameters_set_vhs(resource.vhs_enabled, resource.vhs_tracking_strength, resource.vhs_tape_noise_intensity, resource.vhs_chroma_bleeding_strength, resource.vhs_tape_dropout_intensity, resource.vhs_signal_ringing_strength)
	
static func global_shader_parameters_set_resolution(resolution_mode: int, resolution: Vector2) -> void:
	# Editor preview override for Internal mode
	var effective_resolution_mode = resolution_mode
	if Engine.is_editor_hint() and resolution_mode == 0: # 0 = Internal
		effective_resolution_mode = 1 # 1 = Postprocessing
		
	global_shader_parameter_set("retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, effective_resolution_mode)
	global_shader_parameter_set("retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, resolution)

static func global_shader_parameters_set_сolor_palette(color_palette_texture: Texture2D, color_palette_strength, color_palette_contrast: float, color_palette_brightness: float) -> void:
	global_shader_parameter_set("retro_color_palette_enabled", RenderingServer.GLOBAL_VAR_TYPE_BOOL, color_palette_texture != null)
	global_shader_parameter_set_texture("retro_color_palette_texture", color_palette_texture)
	global_shader_parameter_set("retro_color_palette_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_palette_strength)
	global_shader_parameter_set("retro_color_palette_contrast", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_palette_contrast)
	global_shader_parameter_set("retro_color_palette_brightness", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_palette_brightness * 0.1)

static func global_shader_parameters_set_color_quantization(color_quantization_mode: int, color_quantization_depth: float) -> void:
	global_shader_parameter_set("retro_color_quantization_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, color_quantization_mode)
	global_shader_parameter_set("retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_quantization_depth)

static func global_shader_parameters_set_texture_behavior(texture_affine_mapping_strength: float, texture_masking_threshold: float, vertex_z_fighting_reduction: float) -> void:
	global_shader_parameter_set("retro_texture_affine_mapping_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, texture_affine_mapping_strength)
	global_shader_parameter_set("retro_texture_masking_threshold", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, texture_masking_threshold)
	global_shader_parameter_set("retro_vertex_z_fighting_reduction", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, vertex_z_fighting_reduction)

static func global_shader_parameters_set_vertex_jitter(vertex_jitter_mode: int, vertex_jitter_strength: float, resolution_mode: int, resolution: Vector2, window_size: Vector2i) -> void:
	# Jitter
	# Dynamically scale jitter for Internal resolution mode so it visually matches Postprocessing mode
	var applied_jitter_strength = vertex_jitter_strength
	if resolution_mode == 0 and not Engine.is_editor_hint(): # 0 = Internal
		# Use the actual OS window size, NOT the viewport's visible rect
		# Prevent division by zero during weird window initialization states
		if window_size.x > 0:
			var scale_factor = float(resolution.x) / float(window_size.x)
			applied_jitter_strength *= scale_factor
			
	global_shader_parameter_set("retro_vertex_jitter_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, vertex_jitter_mode)
	global_shader_parameter_set("retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, max(applied_jitter_strength, 0.00001))

static func global_shader_parameters_set_fog(fog_mode: int, fog_color: Color, fog_start_end_distance: Vector2, fog_depth_precision: int) -> void:
	global_shader_parameter_set("retro_fog_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_mode)
	global_shader_parameter_set("retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, fog_color)
	global_shader_parameter_set("retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2, fog_start_end_distance)
	global_shader_parameter_set("retro_fog_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_depth_precision)

static func global_shader_parameters_set_lighting(light_mode: int, light_directional_direction: Vector3, light_directional_intensity: float, light_directional_color: Color) -> void:
	global_shader_parameter_set("retro_light_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, light_mode)
	global_shader_parameter_set("retro_light_directional_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, light_directional_direction)
	global_shader_parameter_set("retro_light_directional_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, light_directional_intensity)
	global_shader_parameter_set("retro_light_directional_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, light_directional_color)

static func global_shader_parameters_set_dithering(dithering_mode: int, dithering_matrix_texture: Texture2D, dithering_strength: float) -> void:
	# Dithering
	var matrix_size := 4
	if dithering_matrix_texture:
		matrix_size = dithering_matrix_texture.get_width()
	global_shader_parameter_set("retro_dithering_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, dithering_mode)
	global_shader_parameter_set_texture("retro_dithering_matrix_texture", dithering_matrix_texture)
	global_shader_parameter_set("retro_dithering_matrix_size", RenderingServer.GLOBAL_VAR_TYPE_INT, matrix_size)
	
	var strength := dithering_strength
	if dithering_matrix_texture == null:
		strength = 0.0
	global_shader_parameter_set("retro_dithering_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, strength)

static func global_shader_parameters_set_crt(enabled : bool, curvature_strength: float, chromatic_aberration_strength: float, scanline_scale: float, scanline_intensity: float, vignette_radius: float, vignette_softness: float) -> void:
	global_shader_parameter_set("retro_crt_enabled", RenderingServer.GLOBAL_VAR_TYPE_BOOL, enabled)
	global_shader_parameter_set("retro_crt_curvature_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, curvature_strength)
	global_shader_parameter_set("retro_crt_curvature_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, curvature_strength)
	global_shader_parameter_set("retro_crt_chromatic_aberration_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, chromatic_aberration_strength)
	global_shader_parameter_set("retro_crt_scanline_scale", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, scanline_scale)
	global_shader_parameter_set("retro_crt_scanline_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, scanline_intensity)
	global_shader_parameter_set("retro_crt_vignette_radius", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, vignette_radius)
	global_shader_parameter_set("retro_crt_vignette_softness", RenderingServer.GLOBAL_VAR_TYPE_FLOAT,vignette_softness)

static func global_shader_parameters_set_vhs(enabled : bool, tracking_strength: float, tape_noise_intensity: float, chroma_bleeding_strength: float, tape_dropout_intensity: float, signal_ringing_strength: float) -> void:
	global_shader_parameter_set("retro_vhs_enabled", RenderingServer.GLOBAL_VAR_TYPE_BOOL, enabled)
	global_shader_parameter_set("retro_vhs_tracking_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, tracking_strength)
	global_shader_parameter_set("retro_vhs_tape_noise_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, tape_noise_intensity)
	global_shader_parameter_set("retro_vhs_chroma_bleeding_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, chroma_bleeding_strength)
	global_shader_parameter_set("retro_vhs_tape_dropout_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, tape_dropout_intensity)
	global_shader_parameter_set("retro_vhs_signal_ringing_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, signal_ringing_strength)
	
static func global_shader_parameter_set(name: String, type, value) -> void:
	if Engine.is_editor_hint():
		if RenderingServer.global_shader_parameter_get(name) == null:
			RenderingServer.global_shader_parameter_add(name, type, value)
	elif not ProjectSettings.has_setting("shader_globals/" + name):
		RenderingServer.global_shader_parameter_add(name, type, value)
		
	RenderingServer.global_shader_parameter_set(name, value)
		
static func global_shader_parameter_set_texture(name: String, tex: Texture2D) -> void:
	# If null, use a small default texture
	# Sampler2D can not be null
	var value : Texture2D = tex
	if value == null:
		var img := Image.create(4, 4, false, Image.FORMAT_R8)
		img.fill(Color(0,0,0)) # white
		var default_tex := ImageTexture.new()
		default_tex.create_from_image(img)
		value = default_tex

	if Engine.is_editor_hint():
		if RenderingServer.global_shader_parameter_get(name) == null:
			RenderingServer.global_shader_parameter_add(name, RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, value)
	elif not ProjectSettings.has_setting("shader_globals/" + name):
		RenderingServer.global_shader_parameter_add(name, RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, value)
		
	RenderingServer.global_shader_parameter_set(name, value)

static func generate_palette_texture(colors: Array[Color], save_path: String) -> void:
	if colors.is_empty(): return
	
	var img := Image.create(colors.size(), 1, false, Image.FORMAT_RGB8)
	for i in range(colors.size()):
		img.set_pixel(i, 0, colors[i])
		
	# Ensure directory exists
	var dir_path = save_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)
		
	# Save image
	img.save_png(save_path)
	
	# Force Editor to see and import the new file
	if Engine.is_editor_hint():
		var editor_interface = Engine.get_singleton("EditorInterface")
		if editor_interface:
			var res_filesystem = editor_interface.get_resource_filesystem()
			res_filesystem.update_file(save_path)
			res_filesystem.scan()
			
	# Force Editor to see and import the new file
	if Engine.is_editor_hint():
		var editor_interface = Engine.get_singleton("EditorInterface")
		if editor_interface:
			var res_filesystem = editor_interface.get_resource_filesystem()
			res_filesystem.update_file(save_path)
			res_filesystem.scan()
