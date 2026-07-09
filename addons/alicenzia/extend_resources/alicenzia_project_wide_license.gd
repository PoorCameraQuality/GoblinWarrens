@tool
extends Resource
class_name ALZProjectWideLicense

@export_custom(PROPERTY_HINT_NONE, "", 6 | PROPERTY_USAGE_READ_ONLY) var owner := ""
@export_custom(PROPERTY_HINT_NONE, "", 6 | PROPERTY_USAGE_READ_ONLY) var license := ""

func _init(_owner :="", _license :="") -> void:
	if !_owner.is_empty():
		owner = _owner
	if !_license.is_empty():
		license = _license
