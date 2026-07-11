class_name ColonySaveData
extends Resource

@export var schema_version: int = 1
@export var tick: int = 0
@export var goblin_cells: PackedVector2Array = PackedVector2Array()
@export var goblin_hunger: PackedFloat32Array = PackedFloat32Array()
@export var goblin_energy: PackedFloat32Array = PackedFloat32Array()
@export var food_cells: PackedVector2Array = PackedVector2Array()
## Authored map resource deltas (Phase 6 prep — unused until colony loads baked maps).
@export var resource_states: Array = [] ## [{placement_id, remaining, felled?}]
@export var map_id: String = ""
@export var map_version: int = 0
@export var warren_cell: Vector2i = Vector2i(-1, -1)
