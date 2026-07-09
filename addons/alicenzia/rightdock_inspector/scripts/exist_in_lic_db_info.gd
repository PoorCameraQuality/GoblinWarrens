@tool
extends VBoxContainer

@onready var info_icon: TextureRect = %InfoIcon
@onready var label: Label = %Label

var panel_themer: Node


func _addon_init() -> void:
	panel_themer = $PanelThemer
	_cleanse_theme()
	panel_themer.replace_panel_themes()


func set_text_by_existance(is_licdata_exists : bool):
	show()
		
	if is_licdata_exists:
		label.text = "License data for this path found on the database and loaded."
		info_icon.texture = get_theme_icon("StatusSuccess", "EditorIcons")
	else:
		label.text ="This path has no license data saved in the database. " + \
					"Create new one (if needed) by filling the fields below and save."
		info_icon.texture = get_theme_icon("StatusWarning", "EditorIcons")


func _cleanse_theme():
	panel_themer.cleanse_panel_themes()
	info_icon.texture = null
	
	
func _exit_tree() -> void:
	info_icon.texture = null
