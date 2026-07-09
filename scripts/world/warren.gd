class_name Warren
extends Building

## Central colony hub. Destruction ends the run.

var max_hp: int = Constants.WARREN_MAX_HP
var hp: int = Constants.WARREN_MAX_HP
var level: int = 1 ## Warren upgrade tier; L3+ mitigates chaotic crowding penalty
var _destroyed: bool = false


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_WARREN)


func setup_warren(cell: Vector2i, def: BuildingDef) -> void:
	setup(cell, def)


func take_damage(amount: int, _source: Node = null) -> void:
	if _destroyed:
		return
	hp = maxi(0, hp - amount)
	if hp <= 0:
		_destroyed = true
		Bus.warren_destroyed.emit()


func is_destroyed() -> bool:
	return _destroyed or hp <= 0


func restore_full() -> void:
	hp = max_hp
	_destroyed = false
