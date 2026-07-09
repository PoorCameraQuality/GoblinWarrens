extends Node

## Global logging. Never use raw print in committed code.


func info(message: String, tag: String = "") -> void:
	var prefix := _prefix(tag)
	print("%s%s" % [prefix, message])


func warn(message: String, tag: String = "") -> void:
	var prefix := _prefix(tag)
	push_warning("%s%s" % [prefix, message])


func error(message: String, tag: String = "") -> void:
	var prefix := _prefix(tag)
	push_error("%s%s" % [prefix, message])


func _prefix(tag: String) -> String:
	if tag.is_empty():
		return "[Log] "
	return "[Log:%s] " % tag
