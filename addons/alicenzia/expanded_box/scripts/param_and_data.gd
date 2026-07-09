@tool
extends HBoxContainer

signal text_changed

@export var param_name := "Param Name":
	set(new_name):
		param_name = new_name
		$Label.text = param_name

@export var placeholder_text := "":
	set(new_plac):
		placeholder_text = new_plac
		$LineEdit.placeholder_text = placeholder_text


func _ready():
	$LineEdit.text_changed.connect(
		func(new_text): text_changed.emit(new_text)
		)


func get_value() -> String:
	return $LineEdit.text


func get_lineedit_node() -> LineEdit:
	return $LineEdit


func set_value(value : String):
	$LineEdit.text = value
