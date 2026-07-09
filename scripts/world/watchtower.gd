class_name Watchtower
extends Building

## Extends raid warning lead time.


func setup_tower(cell: Vector2i, def: BuildingDef) -> void:
	setup(cell, def)


func warning_bonus_seconds() -> float:
	return 5.0
