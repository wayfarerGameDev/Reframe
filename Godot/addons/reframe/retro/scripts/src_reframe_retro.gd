@tool
extends Node3D
class_name ReframeRetro

enum ResolutionMode { Internal, Postprocessing }
enum Mode { None, Individual, Postprocessing }

# Parameters 
@export_group("Shader")
@export var post_processing_shader: Shader = load("res://addons/reframe/retro/shaders/shader_reframe_retro_post_process.gdshader")
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
	
# The MeshInstance3D child
var quad_instance: MeshInstance3D
		
func _notification(what):
	if Engine.is_editor_hint():
		project_settings_update();
		global_shader_parameter_update();
		post_processing_update();
		
func _ready() -> void:
	project_settings_update();
	global_shader_parameter_update();
	post_processing_update();
			
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
	global_shader_parameter_set("reframe_retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, resolution_mode)
	global_shader_parameter_set("reframe_retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, resolution)
	global_shader_parameter_set("reframe_retro_color_quantization_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, color_quantization_mode)
	global_shader_parameter_set("reframe_retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_quantization_depth)
	global_shader_parameter_set("reframe_retro_affine_texture_mapping_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, affine_texture_mapping_strength)
	global_shader_parameter_set("reframe_retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, max(vertex_jitter_strength,0.00001))
	global_shader_parameter_set("reframe_retro_fog_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_mode)
	global_shader_parameter_set("reframe_retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, fog_color)
	global_shader_parameter_set("reframe_retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2, fog_start_end_distance)
	global_shader_parameter_set("reframe_retro_fog_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_depth_precision)

	# Dithering
	global_shader_parameter_set("reframe_retro_dithering_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, dithering_mode)
	global_shader_parameter_set_texture("reframe_retro_dithering_matrix_texture", dithering_matrix_texture)
	var matrix_size := 4
	if dithering_matrix_texture:
		matrix_size = dithering_matrix_texture.get_width()
	global_shader_parameter_set("reframe_retro_dithering_matrix_size", RenderingServer.GLOBAL_VAR_TYPE_INT, matrix_size)
	var strength := dithering_strength
	if dithering_matrix_texture == null:
		strength = 0.0
	global_shader_parameter_set("reframe_retro_dithering_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, strength)

func global_shader_parameter_set(name: String, type, value) -> void:
	if RenderingServer.global_shader_parameter_get(name) == null:
		RenderingServer.global_shader_parameter_add(name, type, value)
	else:
		RenderingServer.global_shader_parameter_set(name, value)
		
func global_shader_parameter_set_texture(name: String, tex: Texture2D) -> void:
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
