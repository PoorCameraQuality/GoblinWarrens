class_name CompiledStrategicMap
extends RefCounted

## Bake-time raid entries, enemy camps, and landmarks (Phase 8).

var map_id: String = ""
var width: int = 0
var height: int = 0
var raid_entries: Array = [] ## FixedMapPlacement-like dicts
var enemy_camps: Array = []
var landmarks: Array = []
var stats: Dictionary = {}


func raid_cells() -> Array:
	var out: Array = []
	for entry in raid_entries:
		if entry is Dictionary:
			out.append(entry.get("cell", Vector2i.ZERO))
	return out


func pick_raid_cell(index: int) -> Vector2i:
	if raid_entries.is_empty():
		return Vector2i(-1, -1)
	var entry = raid_entries[index % raid_entries.size()]
	if entry is Dictionary:
		return entry.get("cell", Vector2i(-1, -1))
	return Vector2i(-1, -1)


func pick_enemy_camp_cell(index: int) -> Vector2i:
	if enemy_camps.is_empty():
		return Vector2i(-1, -1)
	var entry = enemy_camps[index % enemy_camps.size()]
	if entry is Dictionary:
		return entry.get("cell", Vector2i(-1, -1))
	return Vector2i(-1, -1)
