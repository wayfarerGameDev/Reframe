@tool
extends Node3D
class_name ReframeCoreEffect3DPostProcess

# Parameters 
@export var shader: Shader = load("res://addons/reframe/core/shaders/shader_reframe_core_effect_post_process_grayscale.gdshader")

var quad_instance: MeshInstance3D
		
func _notification(what):
	if Engine.is_editor_hint():
		# Property update
		if what == NOTIFICATION_INTERNAL_PROCESS:
			# Call your update functions here to ensure new values are applied
			effect_update()
			return
	
func _ready() -> void:
	# Editor (continuous updates)
	if Engine.is_editor_hint():
		set_process_internal(true)
	# Runtime
	effect_update()
			
func effect_update() -> void:
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
	if shader != null:
		var mat = ShaderMaterial.new()
		mat.shader = shader
		quad_instance.material_override = mat
	else:
		quad_instance.material_override = null
