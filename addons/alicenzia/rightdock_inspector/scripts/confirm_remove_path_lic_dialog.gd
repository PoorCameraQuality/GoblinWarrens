@tool
extends ConfirmationDialog

@onready var path_info: TextEdit = %PathInfo
@onready var main_vbox: VBoxContainer = $MainVbox


func _exit_tree() -> void:
	_update_window_height()
	
	
func show_and_fill_path_info(path : String):
	path_info.text = path
	_update_window_height()
	self.show()


func _update_window_height():
	var min_height := main_vbox.get_combined_minimum_size().y
	self.size.y = roundi(min_height)
