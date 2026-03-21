@tool
extends Node3D
class_name RetroSettingsNode3D

enum ResolutionMode { Internal, Postprocessing }
enum ResolutionAspectMode { Keep, Expand }
enum VertexJitterMode { ClipSpace, ViewSapce }
enum FogMode { None, ObjectVertex, ObjectPixel, Postprocessing }
enum LightMode { None, ObjectVertex, ObjectPixel }
enum Mode { None, Object, Postprocessing }

@export_group("Retro")
@export var resource : RetroSettingsResource
	
var quad_instance: MeshInstance3D
var _last_editor_post_process_state: bool = false
		
func _notification(what):
	if Engine.is_editor_hint():
		# Deletion
		if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_WORLD or what == NOTIFICATION_EXIT_TREE:
			RetroUtilities.global_shader_parameters_set_defaults()
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
	#if light_directional_light != null:
	#	var direction : Vector3 = -(light_directional_light.transform.basis.z).normalized()
	#	light_directional_direction = direction
	
func project_settings_update() -> void:
	# Keep this from breaking the editor while you work
	if Engine.is_editor_hint():
		return
		
	# Window
	var root_window := get_window()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Target Aspect
	var target_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	if resource.resolution_aspect_mode == resource.ResolutionAspectMode.Expand:
		target_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	
	# Resolution mode (Internal)
	if resource.resolution_mode == ResolutionMode.Internal:
		root_window.content_scale_size = resource.resolution
		root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root_window.content_scale_aspect = target_aspect
		root_window.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
		
	# Resolution mode (Postprocessing)
	elif resource.resolution_mode == ResolutionMode.Postprocessing:
		root_window.content_scale_size = resource.resolution
		root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root_window.content_scale_aspect = target_aspect
		root_window.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR

func global_shader_parameter_update() -> void:
	RetroUtilities.global_shader_parameters_set_by_resource(resource, get_window().size)
	
func post_processing_update(force_rebuild: bool = false) -> void:
	# Validate
	if (resource == null):
		return
	
	# Editor preview override for Internal mode
	var effective_resolution_mode = resource.resolution_mode
	if Engine.is_editor_hint() and resource.resolution_mode == ResolutionMode.Internal:
		effective_resolution_mode = ResolutionMode.Postprocessing
	
	# Check persistent state from RenderingServer (Editor Only)
	var is_enabled = false
	if Engine.is_editor_hint():
		var bypass_val = RenderingServer.global_shader_parameter_get("retro_editor_bypass")
		if bypass_val != null:
			is_enabled = bypass_val

	# Validate postprocessing
	var needs_post_processing: bool = (
		effective_resolution_mode == ResolutionMode.Postprocessing or
		resource.color_quantization_mode == Mode.Postprocessing or
		resource.dithering_mode == Mode.Postprocessing or
		resource.fog_mode == FogMode.Postprocessing or
		(is_enabled and Engine.is_editor_hint()) or
		true == true
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
		if resource.post_processing_shader != null: quad_instance.material_override.shader = resource.post_processing_shader
		else: quad_instance.material_override.shader = null
