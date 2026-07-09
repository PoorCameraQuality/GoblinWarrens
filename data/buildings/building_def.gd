class_name BuildingDef
extends Resource

## Static tuning for a placeable building type.

@export var kind: Defs.BuildingKind = Defs.BuildingKind.LUMBER_HUT
@export var display_name: String = "Building"
@export var build_time: float = 8.0 ## seconds of worker hammering at full rate
@export var gold_cost: int = 0
@export var wood_cost: int = 0
@export var stone_cost: int = 0
@export var footprint: Vector2i = Vector2i(1, 1) ## tiles


func cost_dict() -> Dictionary:
	var cost: Dictionary = {}
	if gold_cost > 0:
		cost[Defs.ResourceKind.GOLD] = gold_cost
	if wood_cost > 0:
		cost[Defs.ResourceKind.WOOD] = wood_cost
	if stone_cost > 0:
		cost[Defs.ResourceKind.STONE] = stone_cost
	return cost


func build_progress_per_work_tick() -> float:
	if build_time <= 0.0:
		return 1.0
	return Constants.BUILD_WORK_TIME / build_time
