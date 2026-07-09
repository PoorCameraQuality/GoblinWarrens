@tool
extends VBoxContainer

@export var param_name := "Param Name":
	set(new_name):
		param_name = new_name
		$Label.text = param_name
