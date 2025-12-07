extends SubViewportContainer
class_name ReframeCompositorSubViewport

var sub_viewport : SubViewport
var texture_rect : TextureRect
var image : Image

func _ready() -> void:
	# Editor (continuous updates)
	if Engine.is_editor_hint():
		set_process_internal(true)
	# SubViewport
	sub_viewport = SubViewport.new()
	sub_viewport.size = Vector2(512, 512)
	add_child(sub_viewport)
	# TextureRect
	texture_rect = TextureRect.new()
	sub_viewport.add_child(texture_rect)
	# Image
	image = Image.new()

func _process(delta: float) -> void:
	if ReframeCompositorUtilities.fetch_texture_rid("preview").is_valid():
		ReframeCompositorUtilities.write_texture_rid_to_image(ReframeCompositorUtilities.fetch_texture_rid("preview"),image)
		texture_rect.texture = ImageTexture.create_from_image(image)
	
