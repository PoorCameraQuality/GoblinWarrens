class_name Barracks
extends Building

## Trains hobgoblin warriors on a timer while resources are available.
## Mirrors BreederHut's spawn pattern; combat-unit variant instead of workers.

const _COST := {
	Defs.ResourceKind.WOOD: Constants.BARRACKS_WOOD_COST,
	Defs.ResourceKind.STONE: Constants.BARRACKS_STONE_COST,
}

var _spawn_timer: float = 0.0
var _stockpile: Stockpile = null
var _progress_label: Label3D = null


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_BARRACKS)
	_ensure_progress_label("Warrior")


func setup_barracks(cell: Vector2i, def: BuildingDef, stockpile: Stockpile) -> void:
	setup(cell, def)
	_stockpile = stockpile


func tick_spawn(delta: float, colony: GoblinWarrenColony) -> void:
	if _stockpile == null:
		return
	_spawn_timer += delta
	var can_afford: bool = _stockpile.can_afford(_COST)
	var can_house: bool = colony.count_living_goblins() < colony.get_housing_capacity()
	_update_progress_label(_spawn_timer, Constants.BARRACKS_TRAIN_INTERVAL, can_afford, can_house, "Warrior")
	if _spawn_timer < Constants.BARRACKS_TRAIN_INTERVAL:
		return
	if not can_afford:
		return
	if not can_house:
		return
	if not colony.try_spawn_hobgoblin_warrior_near(self):
		return
	_stockpile.spend(_COST)
	_spawn_timer = 0.0


func _ensure_progress_label(unit_name: String) -> void:
	if _progress_label != null:
		return
	_progress_label = Label3D.new()
	_progress_label.name = "TrainingLabel"
	_progress_label.font_size = 24
	_progress_label.outline_size = 4
	_progress_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_progress_label.position = Vector3(0.0, 2.6, 0.0)
	_progress_label.text = "%s 0%%" % unit_name
	_progress_label.modulate = Color(0.95, 0.95, 0.85)
	add_child(_progress_label)


func _update_progress_label(
	timer: float,
	interval: float,
	can_afford: bool,
	can_house: bool,
	unit_name: String,
) -> void:
	if _progress_label == null:
		return
	if not can_house:
		_progress_label.text = "%s [housing full]" % unit_name
		_progress_label.modulate = Color(1.0, 0.6, 0.35)
		return
	if not can_afford:
		_progress_label.text = "%s [need resources]" % unit_name
		_progress_label.modulate = Color(1.0, 0.75, 0.25)
		return
	var pct: int = int(clampf(timer / interval, 0.0, 1.0) * 100.0)
	_progress_label.text = "%s %d%%" % [unit_name, pct]
	_progress_label.modulate = Color(0.85, 1.0, 0.7) if pct >= 100 else Color(0.95, 0.95, 0.85)
