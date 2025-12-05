@tool
extends EditorPlugin

var custom_button: Button

func _enter_tree():
	ReframeRetroUtilities.global_shader_parameters_defaults()
	ReframeCompositorUtilities.create_editor(self)

func _exit_tree():
	ReframeCompositorUtilities.destroy_editor(self)
	pass

func _process(delta: float) -> void:
	ReframeCompositorUtilities.update_editor(self)
	pass
