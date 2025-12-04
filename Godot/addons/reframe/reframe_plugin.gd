@tool
extends EditorPlugin

var editor_control

func _enter_tree():
	ReframeRetroUtilities.global_shader_parameters_initalize()
	pass

func _exit_tree():
	pass
