class_name GuardPost
extends Building

## Defensive post; nearby goblins prioritize fighting enemies.


func setup_guard(cell: Vector2i, def: BuildingDef) -> void:
	setup(cell, def)


func guard_radius_tiles() -> float:
	return 6.0
