@tool
extends TextEdit

const TEXTEDIT_READONLY_COLOR := Color("838383")

var current_path_flash_tween : Tween

var ed_theme : Theme
var flash_color : Color


func _ready():
	ed_theme = EditorInterface.get_editor_theme()
	flash_color = ed_theme.get_color("font_pressed_color", "Editor")


func animate_current_path_text():
	const RO_COLOR_PROP_PATH := "theme_override_colors/font_readonly_color"
	
	self.set(RO_COLOR_PROP_PATH, flash_color)
	
	if current_path_flash_tween:
		current_path_flash_tween.kill()
	
	current_path_flash_tween = create_tween()
	current_path_flash_tween.tween_property(
		self, RO_COLOR_PROP_PATH + ":r", TEXTEDIT_READONLY_COLOR.r, 0.4
	).set_ease(Tween.EASE_IN).set_delay(0.4)
	
	current_path_flash_tween.parallel().tween_property(
		self, RO_COLOR_PROP_PATH + ":g", TEXTEDIT_READONLY_COLOR.g, 0.4
	).set_ease(Tween.EASE_IN).set_delay(0.4)
	
	current_path_flash_tween.parallel().tween_property(
		self, RO_COLOR_PROP_PATH + ":b", TEXTEDIT_READONLY_COLOR.b, 0.4
	).set_ease(Tween.EASE_IN).set_delay(0.4)
