@tool
extends VBoxContainer
# currently unused

@onready var options_row: HBoxContainer = $OptionsRow
@onready var line_edit_name: LineEdit = $HBoxContainer2/ParamAndData/LineEdit_name
@onready var line_edit_path: LineEdit = $ParamAndDataMax2/LineEdit_path

func _ready() -> void:
	hide()
	#await get_tree().create_timer(2.0, true, true).timeout
	#for paramdata : HBoxContainer in options_row.get_children():
		#print(options_row.size.x)
		#paramdata.custom_minimum_size.x = (options_row.size.x / 3.1)
		#paramdata.update_minimum_size()
		#print(paramdata.custom_minimum_size.x)


func open_and_fill_data(asset_data : Dictionary[String, String]):
	#print(asset_data)
	line_edit_name.text = asset_data["asset_name"]
	line_edit_path.text = asset_data["asset_path"]
	show() 


func _on_save_close_btn_pressed() -> void:
	hide()
