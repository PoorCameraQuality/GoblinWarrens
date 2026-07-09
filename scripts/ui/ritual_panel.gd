class_name RitualPanel
extends Node

## MVP ritual casting UI.

var _colony: GoblinWarrenColony
var _button: Button


func setup(colony: GoblinWarrenColony, button: Button) -> void:
	_colony = colony
	_button = button
	if _button != null:
		_button.text = "Bless Defenders (20 magic)"
		_button.pressed.connect(_on_bless_pressed)


func _on_bless_pressed() -> void:
	if _colony == null:
		return
	if _colony.cast_bless_defender():
		_button.text = "Bless active!"
	else:
		_button.text = "Need 20 magic + Shrine"
