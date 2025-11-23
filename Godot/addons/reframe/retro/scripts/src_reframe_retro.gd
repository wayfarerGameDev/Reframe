@tool
extends Node3D
class_name ReframeRetro

enum Resolution_Mode { Default, Postprocessing }

# Parameters 
@export_group("Shader")
@export var post_processing_shader: Shader = load("res://addons/reframe/retro/shaders/shader_reframe_retro_post_process.gdshader")
@export_group("Resolution")
@export var resolution : Vector2i = Vector2i(320, 240)
@export var resolution_mode : Resolution_Mode = Resolution_Mode.Default;
@export_group("Color")
@export var color_quantization_depth : float = 31.0
@export_group("Dithiring")
@export var dithiring_strength : float = 1
@export_group("Jitter")
@export var vertex_jitter_strength : float = 1
@export var pixel_jitter_strength : float = 1
@export_group("Fog")
@export var fog_color : Color = Color.WHITE
@export var fog_start_end_distance : Vector2 = Vector2(5,30)
@export var depth_precision : float = 32

# The MeshInstance3D child
var quad_instance: MeshInstance3D
		
func _notification(what):
	if Engine.is_editor_hint():
		project_settings_update();
		global_shader_parameter_update();
		post_processing_update();
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func project_settings_update() -> void:
	# get_viewport().size = resolution_mode == Resolution_Mode.Internal and resolution or Vector2i(1152, 648)
	pass
	
func global_shader_parameter_update() -> void:
	global_shader_parameter_set("reframe_retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, resolution)
	global_shader_parameter_set("reframe_retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, resolution_mode)
	global_shader_parameter_set("reframe_retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_quantization_depth)
	global_shader_parameter_set("reframe_retro_dithering_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, dithiring_strength)
	global_shader_parameter_set("reframe_retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, vertex_jitter_strength)
	global_shader_parameter_set("reframe_retro_pixel_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, pixel_jitter_strength)
	global_shader_parameter_set("reframe_retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, fog_color)
	global_shader_parameter_set("reframe_retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2, fog_start_end_distance)
	global_shader_parameter_set("reframe_retro_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, depth_precision)

func global_shader_parameter_set(name: String, type, value) -> void:
	if RenderingServer.global_shader_parameter_get(name) == null:
		RenderingServer.global_shader_parameter_add(name, type, value)
	else:
		RenderingServer.global_shader_parameter_set(name, value)

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
