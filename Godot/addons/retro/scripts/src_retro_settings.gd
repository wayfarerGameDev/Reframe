@tool
extends Node3D
class_name RetroSettings

enum ResolutionMode { Internal, Postprocessing }
enum Mode { None, Individual, Postprocessing }

@export_group("Shader")
@export var post_processing_shader: Shader = load("res://addons/retro/shaders/sdr__retro_post_process.gdshader")
@export_group("Resolution")
@export var resolution_mode : ResolutionMode = ResolutionMode.Postprocessing;
@export var resolution : Vector2i = Vector2i(640, 480)
@export_group("Affine texture mapping")
@export var affine_texture_mapping_strength : float = 1
@export_group("Color")
@export var color_quantization_mode : Mode = Mode.Postprocessing;
@export var color_quantization_depth : float = 31.0
@export_group("Dithiring")
@export var dithering_mode : Mode = Mode.Postprocessing;
@export var dithering_matrix_texture: Texture2D = load("res://addons/retro/textures/tex_retro_dither_matrix_ps1_4x4.png")
@export var dithering_strength : float = 1
@export_group("Jitter")
@export var vertex_jitter_strength : float = 1
@export_group("Fog")
@export var fog_mode : Mode = Mode.Postprocessing;
@export var fog_color : Color = Color.WHITE
@export var fog_start_end_distance : Vector2 = Vector2(5,30)
@export var fog_depth_precision : float = 32
@export_group("Lighting: Directional")
@export var light_directional_light : DirectionalLight3D
@export var light_directional_direction : Vector3 = Vector3(0,1,0);
@export var light_directional_intensity : float = 1;
@export var light_directional_color : Color = Color.BLACK;
	
var quad_instance: MeshInstance3D
		
func _notification(what):
	if Engine.is_editor_hint():
		# Deletion
		if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_WORLD or what == NOTIFICATION_EXIT_TREE:
			RetroUtilities.global_shader_parameters_defaults()
			return
		# Initalize
		if  what == NOTIFICATION_ENTER_WORLD or what == NOTIFICATION_ENTER_TREE:
			project_settings_update()
			global_shader_parameter_update()
			post_processing_update()
		# Property update
		if what == NOTIFICATION_INTERNAL_PROCESS:
			# Call your update functions here to ensure new values are applied
			global_shader_parameter_update()
			post_processing_update()
			return
	
func _ready() -> void:
	# Editor (continuous updates)
	if Engine.is_editor_hint():
		set_process_internal(true)
	# Runtime
	project_settings_update()
	global_shader_parameter_update()
	post_processing_update()
			
func _process(delta: float) -> void:
	# Set directional light direction
	if light_directional_light != null:
		var direction : Vector3 = -(light_directional_light.transform.basis.z).normalized()
		light_directional_direction = direction
	pass

func project_settings_update() -> void:
	# Runtime only
	if Engine.is_editor_hint():
		return
	# Internal	
	if resolution_mode == ResolutionMode.Internal:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_size(resolution)
		var vw := get_viewport()
		# vw.scaling_3d_scale = 1.0
		# vw.scaling_2d_scale = 1.0
		# vw.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		#vw.scaling = Viewport.SCALING_3D_MODE_MAX
	# Other
	if resolution_mode == ResolutionMode.Postprocessing:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		var vw := get_viewport()
		# vw.scaling = Viewport.SCALING_3D_MODE_MAX
		# vw.scaling_2d_scale = 1.0
		# vw.scaling_3d_scale = 1.0
		# vw.size = Vector2i(1152, 648)


func global_shader_parameter_update() -> void:
	# Basic globals
	RetroUtilities.global_shader_parameter_set("retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, resolution_mode)
	RetroUtilities.global_shader_parameter_set("retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, resolution)
	RetroUtilities.global_shader_parameter_set("retro_color_quantization_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, color_quantization_mode)
	RetroUtilities.global_shader_parameter_set("retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_quantization_depth)
	RetroUtilities.global_shader_parameter_set("retro_affine_texture_mapping_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, affine_texture_mapping_strength)
	RetroUtilities.global_shader_parameter_set("retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, max(vertex_jitter_strength,0.00001))
	RetroUtilities.global_shader_parameter_set("retro_fog_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_mode)
	RetroUtilities.global_shader_parameter_set("retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, fog_color)
	RetroUtilities.global_shader_parameter_set("retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2, fog_start_end_distance)
	RetroUtilities.global_shader_parameter_set("retro_fog_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_depth_precision)
	RetroUtilities.global_shader_parameter_set("retro_light_directional_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, light_directional_direction)
	RetroUtilities.global_shader_parameter_set("retro_light_directional_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, light_directional_intensity)
	RetroUtilities.global_shader_parameter_set("retro_light_directional_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, light_directional_color)
	
	# Dithering
	RetroUtilities.global_shader_parameter_set("retro_dithering_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, dithering_mode)
	RetroUtilities.global_shader_parameter_set_texture("retro_dithering_matrix_texture", dithering_matrix_texture)
	var matrix_size := 4
	if dithering_matrix_texture:
		matrix_size = dithering_matrix_texture.get_width()
	RetroUtilities.global_shader_parameter_set("retro_dithering_matrix_size", RenderingServer.GLOBAL_VAR_TYPE_INT, matrix_size)
	var strength := dithering_strength
	if dithering_matrix_texture == null:
		strength = 0.0
	RetroUtilities.global_shader_parameter_set("retro_dithering_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, strength)

func post_processing_update() -> void:
	# MeshInstance3D
	if not quad_instance or not is_instance_valid(quad_instance):
		quad_instance = MeshInstance3D.new()
		add_child(quad_instance)
		quad_instance.name = "ReframeRetroPostProcessScreenQuad"
		quad_instance.extra_cull_margin = INF
		
	# Mesh
	var quad = QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.flip_faces = true
	quad_instance.mesh = quad
	
	# Material
	if post_processing_shader != null:
		var mat = ShaderMaterial.new()
		mat.shader = post_processing_shader
		quad_instance.material_override = mat
	else:
		quad_instance.material_override = null
