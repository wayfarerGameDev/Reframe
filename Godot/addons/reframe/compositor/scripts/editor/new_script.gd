# custom_viewport_button.gd
@tool
extends Button
class_name BUTTON_TEST

signal my_button_pressed(message)

func _ready():
	# Set the text and size
	text = "Apply Reframe Preset"
	set_size(Vector2(160, 24))
	
	# Connect the press signal to a local function
	pressed.connect(_on_pressed)

func _on_pressed():
	# Emit a signal that the main plugin can catch
	emit_signal("my_button_pressed", "Preset application requested!")
	print("Custom Viewport Button Pressed!")
	# In a real tool, you would call the logic to apply the preset here
	# (after getting a reference to the currently selected node).
