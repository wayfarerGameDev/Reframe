@tool
extends Node
class_name ReframeCompsitorEffectNode

enum TargetCompositorMode { WorldEnviorment }

# Parameters
@export_multiline var shader_function_code : String = ""
@export_multiline var shader_main_code : String = ""
@export var alpha : float = 1
@export var enabled : bool = true
@export var target_compositor_mode : TargetCompositorMode = TargetCompositorMode.WorldEnviorment
var compositor_effect : ReframeCompositorEffect
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

func _process(delta: float) -> void:
	add_to_compositor()

func create_effect() -> void:
	# Compositor effect
	if compositor_effect == null:
		compositor_effect = ReframeCompositorEffect.new()
	compositor_effect.enabled = enabled
	compositor_effect.shader_functions_code = shader_function_code
	compositor_effect.shader_main_code = shader_main_code
	compositor_effect.alpha = alpha
	
	# Compositor (World enviorment)
	if target_compositor_mode == TargetCompositorMode.WorldEnviorment:
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
