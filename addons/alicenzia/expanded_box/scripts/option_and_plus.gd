@tool
extends HBoxContainer

signal selected_item_changed(item_name: String)

func _ready() -> void:
	$OptionButton.item_selected.connect(
		func(new_item_index): selected_item_changed.emit(
			$OptionButton.get_item_text(new_item_index))
		)

func get_option_btn() -> OptionButton:
	return $OptionButton

func get_add_btn() -> Button:
	return $Button

func get_value() -> String:
	return 	$OptionButton.get_item_text(
			$OptionButton.get_selected_id())
