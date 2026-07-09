class_name ColonySaveData
extends Resource

@export var schema_version: int = 1
@export var tick: int = 0
@export var goblin_cells: PackedVector2Array = PackedVector2Array()
@export var goblin_hunger: PackedFloat32Array = PackedFloat32Array()
@export var goblin_energy: PackedFloat32Array = PackedFloat32Array()
@export var food_cells: PackedVector2Array = PackedVector2Array()
