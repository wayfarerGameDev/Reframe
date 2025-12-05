@tool
extends EditorPlugin

var custom_button: Button

func _enter_tree():
	ReframeRetroUtilities.global_shader_parameters_defaults()
	ReframeCompositorUtilities.editor_enter(self)

func _exit_tree():
	ReframeCompositorUtilities.editor_exit(self)
	pass

func _process(delta: float) -> void:
	ReframeCompositorUtilities.editor_process(self, delta)
	pass
