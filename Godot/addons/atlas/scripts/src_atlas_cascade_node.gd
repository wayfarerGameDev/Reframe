@tool
extends Node3D
class_name AtlasCascadeNode3D

# Parameters
@export var texture : Texture2D = preload("res://addons/atlas/textures/tex_atlas_blank.png"):
	set(value):
		texture = value
		rebuild()
		pass
@export var world : Vector4 = Vector4(0,1,0,0):
	set(value):
		world = value
		rebuild()
		pass
var is_visible_previous : bool = false

func find_first_world_enviorment(root: Node = get_tree().root) -> WorldEnvironment:
	if root is WorldEnvironment:
		return root
	for child in root.get_children():
		var found := find_first_world_enviorment(child)
		if found:
			return found

	return null

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		rebuild()
	if what == NOTIFICATION_EXIT_TREE:
		rebuild()
	# Move
	if what == NOTIFICATION_DRAG_END:
		rebuild()

func _get_configuration_warnings() -> PackedStringArray:
	if Engine.is_editor_hint() :
		pass
	return []
					
func _ready() -> void:
	# Editor (continuous updates)
	if Engine.is_editor_hint():
		set_process_internal(true)
		
func _process(delta: float) -> void:
	# Editor warning
	if Engine.is_editor_hint():
		update_configuration_warnings()
	# Visibility
	if visible != is_visible_previous:
		rebuild()
	is_visible_previous = visible
		
func rebuild() -> void:
	var parent = get_parent()
	if parent is AtlasMasterNode3D:
		parent.is_cascades_dirty = true
