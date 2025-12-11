@tool
extends EditorPlugin

var custom_button: Button

func _enter_tree():
	FluxUtilities.editor_enter(self)

func _exit_tree():
	FluxUtilities.editor_exit(self)
	pass

func _process(delta: float) -> void:
	FluxUtilities.editor_process(self, delta)
	pass
