@tool
extends Node3D
class_name AtlasMasterNode3D

@export_group("Material")
@export var material: ShaderMaterial = preload("res://addons/atlas/materials/mat_atlas_height_wireframe.tres")
@export_group("Target")
@export var target: Node
@export_group("Cascades")
var cascade_textures : Array[Texture2D]
var cascade_worlds : Array[Vector4]
var is_cascades_dirty : bool = true
const CASCADE_COUNT_MAX : int = 4
const CASCADE_TEXTURE_DEFAULT : Texture2D = preload("res://addons/atlas/textures/tex_atlas_blank.png")
const CASCADE_WORLD_DEFAULT : Vector4 = Vector4(0,1,0,0)
@export_group("State")

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE:
		rebuild_cascades()
		
func _ready() -> void:
	# Editor (continuous updates)
	if Engine.is_editor_hint():
		set_process_internal(true)

func _process(delta: float) -> void:
	# Clamp cascade count
	if cascade_textures.size() > CASCADE_COUNT_MAX:
		cascade_textures = cascade_textures.slice(0, CASCADE_COUNT_MAX - 1)
	rebuild_cascades()
	# Base position
	#if material:
	#	material.set_shader_parameter("base_world",Vector4(-position.x * 100,-position.y * 100,1,1))
	
func rebuild_cascades() -> void:
	# Dirty?
	if not is_cascades_dirty:
		return
	is_cascades_dirty = false
	# Remove old cascades
	cascade_textures.clear()
	cascade_worlds.clear()
	# New cascades
	for child in get_children():
		if child is AtlasCascadeNode3D:
			if child.visible:
				cascade_textures.append(child.texture)
				cascade_worlds.append(child.world)
	# Clamp cascades
	cascade_textures.resize(CASCADE_COUNT_MAX)
	cascade_worlds.resize(CASCADE_COUNT_MAX)
	# Materials
	if material:
		for i in range(CASCADE_COUNT_MAX):
			material.set_shader_parameter("cascade_heightmap_" + str(i), cascade_textures[i])
			material.set_shader_parameter("cascade_world_" + str(i), Vector4(cascade_worlds[i]))
