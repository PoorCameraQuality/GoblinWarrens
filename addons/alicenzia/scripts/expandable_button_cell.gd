@tool
extends Button

signal expand_button(index : int, expand_yes : bool)

var is_currently_expanding := false
var index_meta_name : String
var initial_length : float

func _ready() -> void:
	if custom_minimum_size.x > size.x:
		initial_length = custom_minimum_size.x
	else:
		initial_length = size.x

func _on_pressed() -> void:
	if has_meta(index_meta_name):
		expand_button.emit(get_meta(index_meta_name), is_currently_expanding)
