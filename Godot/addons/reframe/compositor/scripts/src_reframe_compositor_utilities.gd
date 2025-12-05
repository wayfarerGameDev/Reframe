extends RefCounted
class_name ReframeCompositorUtilities

# Consts
const PRESETS_DIRECTORY: String = "res://addons/reframe/compositor/resources/"

# Editor
static var button_spatial : BUTTON_TEST
static var button_canvas : BUTTON_TEST

static func create_editor(editor_plugin : EditorPlugin) -> void:
	if Engine.is_editor_hint():
		button_spatial = BUTTON_TEST.new()
		button_canvas = BUTTON_TEST.new()
		pass

static func update_editor(editor_plugin : EditorPlugin) -> void:
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
		
static func destroy_editor(editor_plugin : EditorPlugin) -> void:
	if Engine.is_editor_hint():
		if button_spatial.get_parent_control() != null:
			editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, button_spatial)
			editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, button_canvas)
		button_spatial.queue_free()
		button_canvas.queue_free()
		button_spatial = null
		button_canvas = null
		pass

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
