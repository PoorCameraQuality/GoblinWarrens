extends RefCounted

## Phase 8 strategic map validation (single static entry — loaded at runtime).

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


static func run() -> Dictionary:
	var Compiler = load("res://scripts/world/map/strategic_map_compiler.gd")
	if Compiler == null:
		return _fail("compiler_load_failed")

	var first = Compiler.compile(MAP_ROOT)
	var second = Compiler.compile(MAP_ROOT)
	if first == null or second == null:
		return _fail("compile_failed")

	var raids_a: int = int(first.stats.get("raid_entry_count", 0))
	var raids_b: int = int(second.stats.get("raid_entry_count", 0))
	if raids_a != raids_b or raids_a < 1:
		return _fail("raid_entry_count=%d/%d" % [raids_a, raids_b])

	for entry in first.raid_entries:
		if str(entry.get("placement_id", "")).is_empty():
			return _fail("missing_raid_placement_id")

	var north_raid := false
	for entry in first.raid_entries:
		var cell: Vector2i = entry.get("cell", Vector2i.ZERO)
		if cell.y < int(first.height) / 3:
			north_raid = true
			break
	if not north_raid:
		return _fail("no_north_raid_entry")

	var log_line := (
		"ok raids=%d camps=%d landmarks=%d"
		% [
			raids_a,
			int(first.stats.get("enemy_camp_count", 0)),
			int(first.stats.get("landmark_count", 0)),
		]
	)
	return {"ok": true, "log_line": log_line, "strategic": first}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
