@tool
extends Control

signal deselect

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index in [1,2,3]:
			deselect.emit()
