@tool
extends HBoxContainer

signal selected_item_changed(item_name: String)

@export var param_name := "Param Name":
	set(new_name):
		param_name = new_name
		$Label.text = param_name

@export var show_add_button := true:
	set(new_add):
		show_add_button = new_add
		var btn : Button = $OptionAndPlus.get_add_btn()
		btn.visible = show_add_button

@export var show_separator := true:
	set(new_sep):
		show_separator = new_sep
		$VSeparator.visible = show_separator

@export var options : Array[String]:
	set(new_opt):
		options = new_opt
		refill_options(options)


func _ready() -> void:
	$OptionAndPlus.selected_item_changed.connect(
		func(new_item_text): selected_item_changed.emit(new_item_text))
	
	
func disable_option_btn(set_disable : bool):
	var opt : OptionButton = $OptionAndPlus.get_option_btn()
	opt.disabled = set_disable
	
	
func refill_options(new_opt_array : Array[String]):
	#print("called")
	var opt : OptionButton = $OptionAndPlus.get_option_btn()
	opt.clear()
	if new_opt_array.size() > 0:
		for item : String in new_opt_array:
			if !item.is_empty():
				opt.add_item(item)


# only works if all options has unique texts
func set_selected_option(selected_opt : String) -> bool:
	var opt : OptionButton = $OptionAndPlus.get_option_btn()
	if selected_opt in options:
		for item_id : int in options.size():
			if opt.get_item_text(item_id) == selected_opt:
				opt.select(item_id)
				return true
	return false
	
	
func get_value() -> String:
	return $OptionAndPlus.get_value()
