class_name BreederHut
extends Building

## Spawns goblin workers (builders) passively up to housing cap.

var _spawn_timer: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_BREEDER)


func setup_breeder(cell: Vector2i, def: BuildingDef) -> void:
	setup(cell, def)


func tick_spawn(delta: float, colony: GoblinWarrenColony) -> void:
	_spawn_timer += delta
	if _spawn_timer < Constants.BREEDER_WORKER_SPAWN_INTERVAL:
		return
	_spawn_timer = 0.0
	colony.try_spawn_goblin_worker_near(self)
