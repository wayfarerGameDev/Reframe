@tool
extends Node3D
class_name RetroSettings

enum ResolutionMode { Internal, Postprocessing }
enum ResolutionAspectMode { Keep, Expand }
enum VertexJitterMode { ClipSpace, ViewSapce }
enum FogMode { None, ObjectVertex, ObjectPixel, Postprocessing }
enum LightMode { None, ObjectVertex, ObjectPixel }
enum Mode { None, Object, Postprocessing }

@export_group("Shader")
@export var post_processing_shader: Shader = load("res://addons/retro/shaders/sdr_retro_post_process.gdshader")
@export_group("Resolution")
@export var resolution_mode : ResolutionMode = ResolutionMode.Postprocessing
@export var resolution_aspect_mode : ResolutionAspectMode = ResolutionAspectMode.Keep
@export var resolution : Vector2i = Vector2i(640, 480)
@export_group("Texture")
@export var texture_affine_mapping_strength : float = 1
@export var texture_masking_threshold : float = 0.5
@export_group("Color")
@export var color_quantization_mode : Mode = Mode.Postprocessing;
@export var color_quantization_depth : float = 31.0
@export var color_palette_texture : Texture2D = null
@export var color_palette_contrast : float = 1.0
@export var color_palette_brightness : float = 1.0
@export_group("Dithiring")
@export var dithering_mode : Mode = Mode.Postprocessing;
@export var dithering_matrix_texture: Texture2D = load("res://addons/retro/textures/tex_retro_dither_matrix_ps1_4x4.png")
@export var dithering_strength : float = 1
@export_group("Vertex")
@export var vertex_jitter_mode : VertexJitterMode = VertexJitterMode.ClipSpace
@export var vertex_jitter_strength : float = 15
@export var vertex_z_fighting_reduction : float = 0
@export_group("Fog")
@export var fog_mode : FogMode = FogMode.ObjectVertex;
@export var fog_color : Color = Color.WHITE
@export var fog_start_end_distance : Vector2 = Vector2(5,30)
@export var fog_depth_precision : float = 32
@export_group("Lighting")
@export var light_mode : LightMode = LightMode.ObjectVertex
@export var light_directional_light : DirectionalLight3D
@export var light_directional_direction : Vector3 = Vector3(0,1,0);
@export var light_directional_intensity : float = 1;
@export var light_directional_color : Color = Color.BLACK;
	
var quad_instance: MeshInstance3D
var _last_editor_post_process_state: bool = false
		
func _notification(what):
	if Engine.is_editor_hint():
		# Deletion
		if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_WORLD or what == NOTIFICATION_EXIT_TREE:
			RetroUtilities.global_shader_parameters_defaults()
			return
		# Initalize
		if	what == NOTIFICATION_ENTER_WORLD or what == NOTIFICATION_ENTER_TREE:
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
		# Pull state from RenderingServer to ensure persistence after save
		var bypass = RenderingServer.global_shader_parameter_get("retro_editor_bypass")
		_last_editor_post_process_state = bypass if bypass != null else false
	# Runtime
	project_settings_update()
	global_shader_parameter_update()
	post_processing_update()
			
func _process(delta: float) -> void:
	# Editor bypass override
	if Engine.is_editor_hint():
		# Ask RenderingServer directly as it survives script reloads/saves
		var current_bypass_state = RenderingServer.global_shader_parameter_get("retro_editor_bypass")
		if current_bypass_state == null: current_bypass_state = false
		
		if current_bypass_state != _last_editor_post_process_state:
			_last_editor_post_process_state = current_bypass_state
			post_processing_update()

	# Set directional light direction
	if light_directional_light != null:
		var direction : Vector3 = -(light_directional_light.transform.basis.z).normalized()
		light_directional_direction = direction
	pass

func project_settings_update() -> void:
	# Keep this from breaking the editor while you work
	if Engine.is_editor_hint():
		return
		
	# Window
	var root_window := get_window()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Target Aspect
	var target_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if resolution_aspect_mode == ResolutionAspectMode.Expand:
		target_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	# Resolution mode (Internal)
	if resolution_mode == ResolutionMode.Internal:
		root_window.content_scale_size = resolution
		root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root_window.content_scale_aspect = target_aspect
		root_window.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		
	# Resolution mode (Postprocessing)
	elif resolution_mode == ResolutionMode.Postprocessing:
		root_window.content_scale_size = resolution
		root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root_window.content_scale_aspect = target_aspect
		root_window.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR

func global_shader_parameter_update() -> void:
	
	# Editor preview override for Internal mode
	var effective_resolution_mode = resolution_mode
	if Engine.is_editor_hint() and resolution_mode == ResolutionMode.Internal:
		effective_resolution_mode = ResolutionMode.Postprocessing
		
	# Basic globals
	RetroUtilities.global_shader_parameter_set("retro_resolution_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, effective_resolution_mode)
	RetroUtilities.global_shader_parameter_set("retro_resolution", RenderingServer.GLOBAL_VAR_TYPE_VEC2, resolution)
	RetroUtilities.global_shader_parameter_set("retro_color_quantization_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, color_quantization_mode)
	RetroUtilities.global_shader_parameter_set("retro_color_quantization_depth", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_quantization_depth)
	RetroUtilities.global_shader_parameter_set("retro_color_palette_enabled", RenderingServer.GLOBAL_VAR_TYPE_BOOL, color_palette_texture != null)
	RetroUtilities.global_shader_parameter_set_texture("retro_color_palette_texture", color_palette_texture)
	RetroUtilities.global_shader_parameter_set("retro_color_palette_contrast", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_palette_contrast)
	RetroUtilities.global_shader_parameter_set("retro_color_palette_brightness", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, color_palette_brightness * 0.1)
	RetroUtilities.global_shader_parameter_set("retro_texture_affine_mapping_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, texture_affine_mapping_strength)
	RetroUtilities.global_shader_parameter_set("retro_texture_masking_threshold", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, texture_masking_threshold)
	RetroUtilities.global_shader_parameter_set("retro_vertex_z_fighting_reduction", RenderingServer.GLOBAL_VAR_TYPE_FLOAT,vertex_z_fighting_reduction)
	RetroUtilities.global_shader_parameter_set("retro_fog_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_mode)
	RetroUtilities.global_shader_parameter_set("retro_fog_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, fog_color)
	RetroUtilities.global_shader_parameter_set("retro_fog_start_end_distance", RenderingServer.GLOBAL_VAR_TYPE_VEC2, fog_start_end_distance)
	RetroUtilities.global_shader_parameter_set("retro_fog_depth_precision", RenderingServer.GLOBAL_VAR_TYPE_INT, fog_depth_precision)
	RetroUtilities.global_shader_parameter_set("retro_light_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, light_mode)
	RetroUtilities.global_shader_parameter_set("retro_light_directional_direction", RenderingServer.GLOBAL_VAR_TYPE_VEC3, light_directional_direction)
	RetroUtilities.global_shader_parameter_set("retro_light_directional_intensity", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, light_directional_intensity)
	RetroUtilities.global_shader_parameter_set("retro_light_directional_color", RenderingServer.GLOBAL_VAR_TYPE_VEC4, light_directional_color)
	
	# Jitter
	# Dynamically scale jitter for Internal resolution mode so it visually matches Postprocessing mode
	var applied_jitter_strength = vertex_jitter_strength
	if resolution_mode == ResolutionMode.Internal and not Engine.is_editor_hint():
		# Use the actual OS window size, NOT the viewport's visible rect
		# Prevent division by zero during weird window initialization states
		var current_window_size = get_window().size
		if current_window_size.x > 0:
			var scale_factor = float(resolution.x) / float(current_window_size.x)
			applied_jitter_strength *= scale_factor
	RetroUtilities.global_shader_parameter_set("retro_vertex_jitter_mode", RenderingServer.GLOBAL_VAR_TYPE_INT, vertex_jitter_mode)
	RetroUtilities.global_shader_parameter_set("retro_vertex_jitter_strength", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, max(applied_jitter_strength, 0.00001))
	
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
	
func post_processing_update(force_rebuild: bool = false) -> void:
	
	# Editor preview override for Internal mode
	var effective_resolution_mode = resolution_mode
	if Engine.is_editor_hint() and resolution_mode == ResolutionMode.Internal:
		effective_resolution_mode = ResolutionMode.Postprocessing
	
	# Check persistent state from RenderingServer
	var is_enabled = RenderingServer.global_shader_parameter_get("retro_editor_bypass")
	if is_enabled == null: is_enabled = false

	# Validate postprocessing
	var needs_post_processing: bool = (
		effective_resolution_mode == ResolutionMode.Postprocessing or
		color_quantization_mode == Mode.Postprocessing or
		dithering_mode == Mode.Postprocessing or
		fog_mode == FogMode.Postprocessing or
		(is_enabled and Engine.is_editor_hint())
	)
	
	# Editor bypass override
	if Engine.is_editor_hint() and not is_enabled:
		needs_post_processing = false
	
	#  Delete post processing
	if not needs_post_processing:
		if is_instance_valid(quad_instance):
			quad_instance.queue_free()
			quad_instance = null
		# Catch any orphaned nodes by name just in case
		else:
			var orphan = get_node_or_null("ReframeRetroPostProcessScreenQuad")
			if orphan: orphan.queue_free()
		return
	
	# Rebuild
	if force_rebuild and is_instance_valid(quad_instance):
		quad_instance.queue_free()
		quad_instance = null
		
	# MeshInstance3D (cleanup)
	# @tool check: prevent orphan nodes from stacking up when reloading scenes
	if not quad_instance:
		quad_instance = get_node_or_null("ReframeRetroPostProcessScreenQuad")
		
	# MeshInstance3D
	if not quad_instance or not is_instance_valid(quad_instance):
		quad_instance = MeshInstance3D.new()
		quad_instance.name = "ReframeRetroPostProcessScreenQuad"
		quad_instance.extra_cull_margin = INF
		quad_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		quad_instance.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		add_child(quad_instance)
		# Mesh
		var quad = QuadMesh.new()
		quad.size = Vector2(2, 2)
		quad.flip_faces = true
		quad_instance.mesh = quad
		# Material
		var mat = ShaderMaterial.new()
		quad_instance.material_override = mat
	
	# Update Shader Dynamically
	if quad_instance.material_override is ShaderMaterial:
		if post_processing_shader != null: quad_instance.material_override.shader = post_processing_shader
		else: quad_instance.material_override.shader = null
