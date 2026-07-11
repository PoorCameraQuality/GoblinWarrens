class_name CompiledResourceMap
extends RefCounted

## Bake-time gameplay resource + tree placements for authored maps (Phase 6).

var map_id: String = ""
var width: int = 0
var height: int = 0
var placements: Array = [] ## PropPlacement entries
var stats: Dictionary = {}


func find_by_placement_id(id: String):
	for entry in placements:
		if entry != null and entry.placement_id == id:
			return entry
	return null


func count_by_kind(kind: int) -> int:
	var total := 0
	for entry in placements:
		if entry != null and int(entry.resource_kind) == kind:
			total += 1
	return total
