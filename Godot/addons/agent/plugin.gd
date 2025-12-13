@tool
extends EditorPlugin

var editor_control: Control

func _enter_tree():
	var editor_theme: Theme = EditorInterface.get_editor_theme()
	editor_control = load("res://addons/agent/ui/ui_agent_editor.tscn").instantiate()
	editor_control.set_theme(editor_theme)
	add_control_to_bottom_panel(editor_control, "Agent")

func _exit_tree():
	remove_control_from_bottom_panel(editor_control)
	pass

func _process(delta: float) -> void:
	pass
