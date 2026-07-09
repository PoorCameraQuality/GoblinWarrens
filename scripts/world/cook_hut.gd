class_name CookHut
extends Building

## Passive food generator. Represents cooking excess forage into rations.
## Complements Mushroom Farm's passive food generation.

var _stockpile: Stockpile = null
var _food_accum: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_COOK_HUT)
	add_to_group(Defs.GROUP_FOOD_PRODUCER)


func setup_cook_hut(cell: Vector2i, def: BuildingDef, stockpile: Stockpile) -> void:
	setup(cell, def)
	_stockpile = stockpile


func tick_passive(delta: float) -> void:
	if _stockpile == null:
		return
	_food_accum += delta * Constants.COOK_HUT_FOOD_PER_SECOND
	while _food_accum >= 1.0:
		_stockpile.deposit(Defs.ResourceKind.FOOD, 1)
		_food_accum -= 1.0
