@tool
extends Node

@export var chosen_theme_color_name := "disabled_bg_color"
@export var panels_to_theme : Array[PanelContainer]

func cleanse_panel_themes():
	for panel : PanelContainer in panels_to_theme:
		if not panel.is_inside_tree():
			continue
			
		panel.remove_theme_stylebox_override("panel")
		

func replace_panel_themes():
	for panel : PanelContainer in panels_to_theme:
		if not panel.is_inside_tree():
			continue
			
		panel.set_theme( EditorInterface.get_editor_theme() )
		
		var editor_disabled_bg_color = panel.get_theme_color(chosen_theme_color_name, "Editor")
		var new_stylebox_panel := StyleBoxFlat.new()
		new_stylebox_panel.bg_color = editor_disabled_bg_color
		#new_stylebox_panel.border_color = editor_disabled_bg_color
		panel.add_theme_stylebox_override("panel", new_stylebox_panel)


func _exit_tree() -> void:
	cleanse_panel_themes()
