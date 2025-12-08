extends RefCounted
class_name ReframeCompositorUtilities

# Consts
const PRESETS_DIRECTORY: String = "res://addons/reframe/compositor/resources/"
const RESOLUTION_TEXTURE_MIN: Vector2i = Vector2i(32,32)
const RESOLUTION_TEXTURE_MAX: Vector2i = Vector2i(1024,1024)

# Editor
static var editor_button_spatial : MenuButton
static var editor_button_canvas : MenuButton
static var editor_preview_texture_rect : TextureRect
static var editor_preview_image : Image
static var editor_preview_control

# Runtime
static var rid_texture_map : Dictionary = {}

static func create_texture_rid(name: StringName, resolution : Vector2i) -> RID:
	# Clamp resolution
	resolution.x = clamp(resolution.x, RESOLUTION_TEXTURE_MIN.x, RESOLUTION_TEXTURE_MAX.x)
	resolution.y = clamp(resolution.y, RESOLUTION_TEXTURE_MIN.y, RESOLUTION_TEXTURE_MAX.y)
	# Rendering device
	var rendering_device = RenderingServer.get_rendering_device()
	# Texture (Fetch)
	# Remove if format changed so new texture can be created
	var texture_rid : RID
	if rid_texture_map.has(name):
		texture_rid = rid_texture_map[name]
		var existing_format = rendering_device.texture_get_format(texture_rid)
		if existing_format.width == resolution.x and existing_format.height == resolution.y:
			return texture_rid
		else:
			rendering_device.free_rid(texture_rid)
			rid_texture_map.erase(name)
	# Texture Format
	var texture_format = RDTextureFormat.new()
	texture_format.width = resolution.x
	texture_format.height = resolution.y
	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	texture_format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	# Image
	var image = Image.create(resolution.x,resolution.y, false, Image.FORMAT_RGBAF)	
	image.fill(Color.DEEP_PINK)
	# Texture (New)
	texture_rid = rendering_device.texture_create(texture_format,RDTextureView.new(),[image.get_data()]);
	rid_texture_map[name] = texture_rid
	return texture_rid

static func fetch_texture_rid(name: StringName) -> RID:
	if rid_texture_map.has(name):
		return rid_texture_map[name]
	else: return RID()

static func write_texture_rid_to_sub_viewport(texture_rid : RID, sub_viewport : SubViewport):
	# Rendering device
	var rendering_device = RenderingServer.get_rendering_device()
	# Image
	var texture_data : PackedByteArray = rendering_device.texture_get_data(texture_rid, 0);
	var texture_format = rendering_device.texture_get_format(texture_rid)
	# Sub Viewport
	sub_viewport.size = Vector2(texture_format.width,texture_format.height)
			
static func write_texture_rid_to_image(texture_rid : RID, image : Image) -> void:
	# Rendering device
	var rendering_device = RenderingServer.get_rendering_device()
	# Image
	var texture_data : PackedByteArray = rendering_device.texture_get_data(texture_rid, 0);
	var texture_format = rendering_device.texture_get_format(texture_rid)
	image.set_data(texture_format.width,texture_format.height,false, Image.FORMAT_RGBAF,texture_data);
			
static func editor_enter(editor_plugin : EditorPlugin) -> void:
	if Engine.is_editor_hint():
		# Preview
		editor_preview_texture_rect = TextureRect.new()
		editor_preview_image = Image.new()
		editor_preview_control = Control.new()
		editor_preview_control.add_child(editor_preview_texture_rect, true)
		editor_plugin.add_control_to_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_SIDE_LEFT,editor_preview_control)
		# Moved to process so we can use gpu
		# Presets button (Spatial)
		editor_button_spatial = MenuButton.new()
		editor_button_spatial.text = "Presets"
		editor_button_spatial.flat = true
		editor_button_spatial.pressed.connect(editor_menu_button_populate_by_presets.bind(editor_button_spatial))
		editor_button_spatial.get_popup().id_pressed.connect(editor_menu_button_preset_selected)
		# Presets button (Canvas)
		editor_button_canvas = MenuButton.new()
		editor_button_canvas.text = "Presets"
		editor_button_canvas.flat = true
		editor_button_canvas.pressed.connect(editor_menu_button_populate_by_presets.bind(editor_button_canvas))
		editor_button_canvas.get_popup().id_pressed.connect(editor_menu_button_preset_selected)

static func editor_exit(editor_plugin : EditorPlugin) -> void:
	if Engine.is_editor_hint():
		# Preview
		editor_preview_texture_rect.free()
		editor_preview_texture_rect = null
		editor_preview_image.free()
		editor_preview_image = null
		# Presets button (Spatial)
		editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_button_spatial)
		editor_button_spatial.queue_free()
		editor_button_spatial = null
		# Presets button (Canvas)
		editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, editor_button_canvas)
		editor_button_canvas.queue_free()
		editor_button_spatial = null
		editor_button_canvas = null
		
static func editor_process(editor_plugin : EditorPlugin, delta: float) -> void:
	if Engine.is_editor_hint():
		var r = ReframeCompositorUtilities.fetch_texture_rid("preview")
		if r:
			ReframeCompositorUtilities.write_texture_rid_to_image(r,editor_preview_image )
			editor_preview_texture_rect.texture = ImageTexture.create_from_image(editor_preview_image)
		# Selected nodes
		var selected_nodes: Array = EditorInterface.get_selection().get_selected_nodes()
		# Presets (Visible)
		if selected_nodes.size() > 0 and selected_nodes[0] is ReframeCompsitorEffectNode and editor_button_spatial.get_parent_control() == null:
			editor_plugin.add_control_to_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_button_spatial)
			editor_plugin.add_control_to_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, editor_button_canvas)		
		# Presets (Hidden)
		else : if (selected_nodes.size() == 0 or selected_nodes[0] is not ReframeCompsitorEffectNode) and editor_button_spatial.get_parent_control() != null:
				editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_SPATIAL_EDITOR_MENU, editor_button_spatial)
				editor_plugin.remove_control_from_container(editor_plugin.CONTAINER_CANVAS_EDITOR_MENU, editor_button_canvas)
	
static func editor_menu_button_populate_by_presets(menu_button: MenuButton) -> void:
	if Engine.is_editor_hint():
		# Populate
		menu_button.get_popup().clear()
		var presets = get_presets()
		menu_button.get_popup().add_item("None", 0)
		for i in presets.size():
			menu_button.get_popup().add_item(presets[i].name, i + 1)
	
static func editor_menu_button_preset_selected(id: int) -> void:
	if Engine.is_editor_hint():
		var selected_node: ReframeCompsitorEffectNode = EditorInterface.get_selection().get_selected_nodes()[0] as ReframeCompsitorEffectNode
		var preset = get_presets()[id - 1] # To offset None option
		#None
		if id == 0:
			selected_node.name = "ReframeCompsitorEffect_None"
			selected_node.uniforms = []
			selected_node.world_alpha = 1
			selected_node.world_resolution = Vector2i(256,256)
			selected_node.functions = ""
			selected_node.main = ""
			selected_node.domain = ReframeCompositorComputeShader.Domain.COMPOSITOR
			selected_node.target_compositor_mode = ReframeCompsitorEffectNode.TargetCompositorMode.WORLD_ENVIORMENT
		#Preset
		else:
			selected_node.name = "ReframeCompsitorEffect_" + preset.name
			selected_node.uniforms = preset.uniforms
			selected_node.world_alpha = preset.world_alpha
			selected_node.world_resolution = preset.world_resolution
			selected_node.functions = preset.functions
			selected_node.main = preset.main
			selected_node.domain = preset.domain
			selected_node.target_compositor_mode = preset.target_compositor_mode
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
