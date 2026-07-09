class_name BlacksmithBuilding
extends Building

## Passive attack-damage multiplier for all goblins while at least one Blacksmith stands.
##
## Group-membership acts as the effect signal — see Goblin._has_blacksmith().


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_BLACKSMITH)
