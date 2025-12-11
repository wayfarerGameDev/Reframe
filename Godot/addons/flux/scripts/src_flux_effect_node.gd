@tool
extends Node
class_name FluxEffectNode


enum TargetCompositorMode { WORLD_ENVIORMENT }
# Parameters
@export_group("Uniforms")
@export var uniforms : Array
@export_group("World")
@export var world_resolution : Vector2i
@export var world_alpha: float = 1
@export_group("Code")
@export_multiline var functions : String = ""
@export_multiline var main : String = ""
@export_group("Settings")
@export var domain: FluxComputeShader.Domain
@export var target_compositor_mode : TargetCompositorMode = TargetCompositorMode.WORLD_ENVIORMENT

var flux_compute_shader : FluxComputeShader
var compositor_effect : FluxCompositorEffect
var compositor : Compositor

func find_first_world_enviorment(root: Node = get_tree().root) -> WorldEnvironment:
	if root is WorldEnvironment:
		return root
	for child in root.get_children():
		var found := find_first_world_enviorment(child)
		if found:
			return found

	return null

func _notification(what):
	# Exit
	if what == NOTIFICATION_PREDELETE or what == NOTIFICATION_EXIT_TREE:
		flux_compute_shader._notification(what)
		remove_from_compositor()
		return
	# Enter
	# We just clear so we rebuild with order of nodes
	if what == NOTIFICATION_ENTER_TREE:
		clear_compositor()
		return
	# Move
	# We just clear so we rebuild with order of nodes
	if what == NOTIFICATION_DRAG_END:
		clear_compositor()
						
func _ready() -> void:
	# Editor (continuous updates)
	if Engine.is_editor_hint():
		set_process_internal(true)
			
func _get_configuration_warnings() -> PackedStringArray:
	if Engine.is_editor_hint() :
		if not compositor_effect.flux_compute_shader.shader.is_valid():
			return ["Invalid shader"]
	return []
		

func _process(delta: float) -> void:
	# Editor warning
	if Engine.is_editor_hint():
		update_configuration_warnings()
	# Domain (Compositor)
	if domain == FluxComputeShader.Domain.COMPOSITOR:
		add_to_compositor()
	# Domain (Render Target)
	else:
		flux_compute_shader.dispatch_shader_to_render_target()
		remove_from_compositor()

func preview() -> void:
	if Engine.is_editor_hint():
		flux_compute_shader.preview()		
	
func create_effect() -> void:
	# Resolution
	world_resolution.x = clamp(world_resolution.x, FluxUtilities.RESOLUTION_TEXTURE_MIN.x, FluxUtilities.RESOLUTION_TEXTURE_MAX.x)
	world_resolution.y = clamp(world_resolution.y, FluxUtilities.RESOLUTION_TEXTURE_MIN.y, FluxUtilities.RESOLUTION_TEXTURE_MAX.y)
	# Compute shader
	if flux_compute_shader == null:
		flux_compute_shader = FluxComputeShader.new()
		flux_compute_shader.init()
	flux_compute_shader.uniforms = uniforms
	flux_compute_shader.world_alpha = world_alpha
	flux_compute_shader.world_resolution = world_resolution
	flux_compute_shader.shader_functions_code = functions
	flux_compute_shader.shader_main_code = main
	flux_compute_shader.domain = domain
	# Compositor effect
	if compositor_effect == null:
		compositor_effect = FluxCompositorEffect.new()
		compositor_effect.flux_compute_shader = flux_compute_shader
	# Compositor (World enviorment)
	if target_compositor_mode == TargetCompositorMode.WORLD_ENVIORMENT:
		var world_enviorment = find_first_world_enviorment()
		if world_enviorment:
			compositor = world_enviorment.compositor

func clear_compositor() -> void:
	create_effect()
	# Clear compositor
	# For some reason it won't work adding to array
	# I made copy that I added to and than overwrite original array
	if compositor and compositor_effect:
		compositor.compositor_effects = []
	
func remove_from_compositor() -> void:	
	create_effect()
	# Remove effect
	# For some reason it won't work adding to array
	# I made copy that I added to and than overwrite original array
	if compositor and compositor_effect:
		if compositor.compositor_effects.has(compositor_effect):
			var new_effects = compositor.compositor_effects.duplicate() 
			new_effects.remove_at(compositor.compositor_effects.find(compositor_effect))
			compositor.compositor_effects = new_effects
				
func add_to_compositor() -> void:	
	create_effect()
	# Add effect
	# For some reason it won't work adding to array
	# I made copy that I added to and than overwrite original array
	if compositor and compositor_effect:
		if not compositor.compositor_effects.has(compositor_effect):
			var new_effects = compositor.compositor_effects.duplicate() 
			new_effects.append(compositor_effect)
			compositor.compositor_effects = new_effects
