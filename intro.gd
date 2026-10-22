
extends Control

@onready var background: TextureRect = $TextureRect
@onready var start_button: Button = $Button

func _ready() -> void:
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	start_button.text = "START"
	start_button.custom_minimum_size = Vector2(180, 55)

	

	start_button.add_theme_font_size_override("font_size", 24)
	start_button.add_theme_color_override(
		"font_color", Color("#ffffff")
	)

	# Connect the button to the function below.
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	var error = get_tree().change_scene_to_file("res://Main.tscn")

	if error != OK:
		push_error("Could not load Main.tscn. Error: " + str(error))
