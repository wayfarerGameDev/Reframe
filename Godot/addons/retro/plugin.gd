@tool
extends EditorPlugin

var post_process_toggle_2d: Button
var post_process_toggle_3d: Button
var editor_selection: EditorSelection

func _enter_tree():
	
	# Initialize default shader parameters
	RetroUtilities.global_shader_parameters_defaults()
	
	# Godot styles
	var editor_base = get_editor_interface().get_base_control()
	var btn_icon = editor_base.get_theme_icon("SubViewport", "EditorIcons")
	var pressed_style = editor_base.get_theme_stylebox("pressed", "Button")
	var hover_pressed_style = editor_base.get_theme_stylebox("hover_pressed", "Button")

	# Load persistent state from Editor Settings (default to false if not found)
	var settings = get_editor_interface().get_editor_settings()
	var saved_state = false
	if settings.has_setting("retro_plugin/editor_post_process_enabled"):
		saved_state = settings.get_setting("retro_plugin/editor_post_process_enabled")
		
	# Create post-process toggle (2d)
	post_process_toggle_2d = Button.new()
	post_process_toggle_2d.icon = btn_icon
	post_process_toggle_2d.flat = true
	post_process_toggle_2d.add_theme_stylebox_override("pressed", pressed_style)
	post_process_toggle_2d.add_theme_stylebox_override("hover_pressed", hover_pressed_style)
	post_process_toggle_2d.focus_mode = Control.FOCUS_NONE 
	post_process_toggle_2d.tooltip_text = "Toggle Retro Post-Processing\nEnables or disables all retro post-processing effects in the editor viewport."
	post_process_toggle_2d.toggle_mode = true 
	post_process_toggle_2d.button_pressed = saved_state # Set initial visual state
	post_process_toggle_2d.toggled.connect(_on_post_process_toggled)
	post_process_toggle_2d.hide() 
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, post_process_toggle_2d)
	
	# Create post-process toggle (3d)
	post_process_toggle_3d = Button.new()
	post_process_toggle_3d.icon = btn_icon
	post_process_toggle_3d.flat = true
	post_process_toggle_3d.add_theme_stylebox_override("pressed", pressed_style)
	post_process_toggle_3d.add_theme_stylebox_override("hover_pressed", hover_pressed_style)
	post_process_toggle_3d.focus_mode = Control.FOCUS_NONE 
	post_process_toggle_3d.tooltip_text = "Toggle Retro Post-Processing\nEnables or disables all retro post-processing effects in the editor viewport."
	post_process_toggle_3d.toggle_mode = true
	post_process_toggle_3d.button_pressed = saved_state # Set initial visual state
	post_process_toggle_3d.toggled.connect(_on_post_process_toggled)
	post_process_toggle_3d.hide() 
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, post_process_toggle_3d)

	# Set up editor selection signal
	editor_selection = get_editor_interface().get_selection()
	editor_selection.selection_changed.connect(_on_selection_changed)

func _exit_tree():
	
	# Cleanup post-process toggle (2d)
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, post_process_toggle_2d)
	post_process_toggle_2d.queue_free()
		
	# Cleanup post-process toggle (3d)
	remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, post_process_toggle_3d)
	post_process_toggle_3d.queue_free()
		
	# Cleanup editor selection signal
	if editor_selection and editor_selection.selection_changed.is_connected(_on_selection_changed):
		editor_selection.selection_changed.disconnect(_on_selection_changed)

func _on_selection_changed():
	
	# Check if RetroSettings node is selected
	var selected_nodes = editor_selection.get_selected_nodes()
	var is_retro_selected = false
	for node in selected_nodes:
		if node is RetroSettings:
			is_retro_selected = true
			break
			
	# Toggle post-process toggle visibility (2d/3d)
	post_process_toggle_2d.visible = is_retro_selected
	post_process_toggle_3d.visible = is_retro_selected
	
func _on_post_process_toggled(is_pressed: bool):
	
	# Keep post-process toggle buttons visually synced without triggering an infinite loop
	post_process_toggle_2d.set_pressed_no_signal(is_pressed)
	post_process_toggle_3d.set_pressed_no_signal(is_pressed)
		
	# Update the engine's global shader state (this survives saves/reloads)
	RetroUtilities.global_shader_parameter_set("retro_editor_bypass", RenderingServer.GLOBAL_VAR_TYPE_BOOL, is_pressed)
