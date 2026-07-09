class_name MushroomFarm
extends Building

## Passive above-ground food production.

var _stockpile: Stockpile = null
var _accum: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_FOOD_PRODUCER)


func setup_farm(cell: Vector2i, def: BuildingDef, stockpile: Stockpile) -> void:
	setup(cell, def)
	_stockpile = stockpile


func tick_production(delta: float) -> void:
	if _stockpile == null:
		return
	_accum += delta * Constants.MUSHROOM_FOOD_PER_SECOND
	while _accum >= 1.0:
		_stockpile.deposit(Defs.ResourceKind.FOOD, 1)
		_accum -= 1.0
