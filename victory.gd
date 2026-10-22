
extends Control

@onready var background: TextureRect = $Background

func _ready() -> void:
	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
