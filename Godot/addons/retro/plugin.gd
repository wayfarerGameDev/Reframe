@tool
extends EditorPlugin

var custom_button: Button

func _enter_tree():
	RetroUtilities.global_shader_parameters_defaults()
