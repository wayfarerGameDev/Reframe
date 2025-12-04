@tool
extends Node3D
class_name ReframeRetroSettings

enum ResolutionMode { Internal, Postprocessing }
enum Mode { None, Individual, Postprocessing }

# Parameters 
@export_group("Materials")
@export var post_processing_material: Material = load("res://addons/reframe/retro/materials/mat_reframe_retro_postprocessing_base.tres")
@export_group("Resolution")
@export var resolution_mode : ResolutionMode = ResolutionMode.Postprocessing;
@export var resolution : Vector2i = Vector2i(1152, 648)
@export_group("Affine texture mapping")
@export var affine_texture_mapping_strength : float = 1
@export_group("Color")
@export var color_quantization_mode : Mode = Mode.Postprocessing;
@export var color_quantization_depth : float = 31.0
@export_group("Dithiring")
@export var dithering_mode : Mode = Mode.Postprocessing;
@export var dithering_matrix_texture: Texture2D = load("res://addons/reframe/retro/textures/tex_reframe_retro_dither_matrix_ps1_4x4.png")
@export var dithering_strength : float = 1
@export_group("Jitter")
@export var vertex_jitter_strength : float = 1
@export_group("Fog")
@export var fog_mode : Mode = Mode.Postprocessing;
@export var fog_color : Color = Color.WHITE
@export var fog_start_end_distance : Vector2 = Vector2(5,30)
@export var fog_depth_precision : float = 32
	
var quad_instance: MeshInstance3D
		
func _notification(what):
	if Engine.is_editor_hint():
		_ready()
		
func _ready() -> void:
	project_settings_update()
	global_shader_parameter_update()
	post_processing_update()
			
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#project_settings_update()
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
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, resolution_mode)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, resolution)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_color_quantization_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, color_quantization_mode)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_quantization_depth)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_affine_texture_mapping_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, affine_texture_mapping_strength)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, max(vertex_jitter_strength,0.00001))
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_fog_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_mode)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, fog_color)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2, fog_start_end_distance)
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_fog_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_depth_precision)

	# Dithering
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_dithering_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, dithering_mode)
	ReframeRetroUtilities.global_shader_parameter_set_texture("reframe_retro_dithering_matrix_texture", dithering_matrix_texture)
	var matrix_size := 4
	if dithering_matrix_texture:
		matrix_size = dithering_matrix_texture.get_width()
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_dithering_matrix_size", RenderingServer.GLOBAL_VAR_TYPE_INT, matrix_size)
	var strength := dithering_strength
	if dithering_matrix_texture == null:
		strength = 0.0
	ReframeRetroUtilities.global_shader_parameter_set("reframe_retro_dithering_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, strength)

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
	quad_instance.material_override = post_processing_material;
