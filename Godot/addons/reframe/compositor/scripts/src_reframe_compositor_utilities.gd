extends RefCounted
class_name ReframeCompositorUtilities

# Consts
const PRESETS_DIRECTORY: String = "res://addons/reframe/compositor/resources/"

# Editor
static var button_spatial : MenuButton
static var button_canvas : MenuButton

static func editor_enter(editor_plugin : EditorPlugin) -> void:
	if Engine.is_editor_hint():
		# Presets button (Spatial)
		button_spatial = MenuButton.new()
		button_spatial.text = "Presets"
		button_spatial.flat = true
		button_spatial.pressed.connect(editor_menu_button_populate_by_presets.bind(button_spatial))
		button_spatial.get_popup().id_pressed.connect(editor_menu_button_preset_selected)
		# Presets button (Canvas)
		button_canvas = MenuButton.new()
		button_canvas.text = "Presets"
		button_canvas.flat = true
		button_canvas.pressed.connect(editor_menu_button_populate_by_presets.bind(button_canvas))
		button_canvas.get_popup().id_pressed.connect(editor_menu_button_preset_selected)

static func editor_exit(editor_plugin : EditorPlugin) -> void:
	if Engine.is_editor_hint():
		# Presets button (Spatial)
		editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, button_spatial)
		button_spatial.queue_free()
		button_spatial = null
		# Presets button (Canvas)
		editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, button_canvas)
		button_canvas.queue_free()
		button_spatial = null
		button_canvas = null
		
static func editor_process(editor_plugin : EditorPlugin, delta: float) -> void:
	if Engine.is_editor_hint():
		var selected_nodes: Array = EditorInterface.get_selection().get_selected_nodes()
		# Visible
		if selected_nodes.size() > 0 and selected_nodes[0] is ReframeCompsitorEffectNode and button_spatial.get_parent_control() == null:
			editor_plugin.add_control_to_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, button_spatial)
			editor_plugin.add_control_to_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, button_canvas)		
		# Hidden
		else : if (selected_nodes.size() == 0 or selected_nodes[0] is not ReframeCompsitorEffectNode) and button_spatial.get_parent_control() != null:
				editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, button_spatial)
				editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, button_canvas)
	
static func editor_menu_button_populate_by_presets(menu_button: MenuButton) -> void:
	if Engine.is_editor_hint():
		# Populate
		menu_button.get_popup().clear()
		var presets = get_presets()
		for i in presets.size():
			menu_button.get_popup().add_item(presets[i].name, i)
	
static func editor_menu_button_preset_selected(id: int) -> void:
	if Engine.is_editor_hint():
		var selected_node: ReframeCompsitorEffectNode = EditorInterface.get_selection().get_selected_nodes()[0] as ReframeCompsitorEffectNode
		var preset = get_presets()[id]
		selected_node.shader_function_code = preset.shader_functions_code
		selected_node.shader_main_code = preset.shader_main_code
		selected_node.alpha = preset.alpha
		selected_node.name = "ReframeCompsitorEffect_" + preset.name
		
static func get_presets() -> Array[ReframeCompositorEffectPreset]:
	var presets: Array[ReframeCompositorEffectPreset] = []
	
	var dir = DirAccess.open(PRESETS_DIRECTORY)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Only process resource files
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var path = PRESETS_DIRECTORY + file_name
				
				# ResourceLoader.load() is used to load the resource content
				var resource = ResourceLoader.load(path)
				
				# Verify that the loaded resource is of the expected type
				if resource is ReframeCompositorEffectPreset:
					presets.append(resource as ReframeCompositorEffectPreset)
				else:
					# Optional: Log an error if a file in the folder is not the correct resource type
					if resource != null:
						push_warning("File at path '%s' is not a ReframeCompositorEffectPreset." % path)
				
			file_name = dir.get_next()
			
		dir.list_dir_end()
	else:
		push_error("Could not open presets directory: %s" % PRESETS_DIRECTORY)

	return presets
