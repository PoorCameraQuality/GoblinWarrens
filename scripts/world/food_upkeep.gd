class_name FoodUpkeep
extends RefCounted

## Colony-wide food consumption and starvation pressure.

var _timer: float = 0.0
var _failed_ticks: int = 0


func tick(delta: float, stockpile: Stockpile, goblins: Array[Goblin]) -> bool:
	_timer += delta
	if _timer < Constants.FOOD_UPKEEP_INTERVAL:
		return false
	_timer = 0.0
	var eaters: int = count_food_consumers(goblins)
	if eaters <= 0:
		return false
	var needed: int = eaters * Constants.FOOD_PER_GOBLIN_PER_TICK
	var fed: bool = stockpile.try_spend(Defs.ResourceKind.FOOD, needed)
	if fed:
		_failed_ticks = 0
		for goblin in goblins:
			if is_instance_valid(goblin) and not goblin.is_foblin():
				goblin.on_fed()
	else:
		_failed_ticks += 1
		Bus.food_shortage.emit(0)
		for goblin in goblins:
			if is_instance_valid(goblin) and not goblin.is_foblin():
				goblin.on_food_shortage()
	return _failed_ticks >= Constants.FOOD_COLLAPSE_TICKS


static func count_food_consumers(goblins: Array[Goblin]) -> int:
	var count := 0
	for goblin in goblins:
		if is_instance_valid(goblin) and not goblin.is_foblin():
			count += 1
	return count


func reset() -> void:
	_timer = 0.0
	_failed_ticks = 0
