extends SceneTree

## Phase 2 semantic map + grid compile regression suite.
## godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd

const _Importer := preload("res://scripts/world/map/map_semantic_importer.gd")
const _Compiler := preload("res://scripts/world/map/grid_compiler.gd")
const _MovementAdapter := preload("res://scripts/agents/movement_adapter.gd")
const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


func _init() -> void:
	var started_ms := Time.get_ticks_msec()
	for watched in [
		"res://scripts/world/map/baked_grid_compile.gd",
		"res://scripts/world/map/grid_compiler.gd",
		"res://scripts/world/map/map_semantic_importer.gd",
	]:
		var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(watched))
		if text.contains("class_name: String") or text.contains("class_name:String"):
			print("[semantic-map-regression] FAIL reserved_keyword_class_name_param")
			quit(1)
			return

	var import_report: Dictionary = _Importer.import_map(MAP_ROOT, Vector2i(350, 350))
	if not bool(import_report.get("ok", false)):
		print("[semantic-map-regression] FAIL fresh_import_failed")
		quit(1)
		return
	var validation: Dictionary = import_report.get("validation", {})
	if not bool(validation.get("pass", false)):
		print("[semantic-map-regression] FAIL import_validation")
		quit(1)
		return
	if int(validation.get("swamp_overlaps_road_pixels", -1)) != 0:
		print("[semantic-map-regression] FAIL swamp_road_overlap")
		quit(1)
		return
	if int(validation.get("road_pixels_not_full_speed", -1)) != 0:
		print("[semantic-map-regression] FAIL road_not_full_speed")
		quit(1)
		return
	if int(validation.get("road_pixels_not_no_scatter", -1)) != 0:
		print("[semantic-map-regression] FAIL road_not_no_scatter")
		quit(1)
		return

	var grid = _Compiler.compile_map(MAP_ROOT, Vector2i(350, 350))
	if grid == null:
		print("[semantic-map-regression] FAIL compile")
		quit(1)
		return

	var grid_b = _Compiler.compile_map(MAP_ROOT, Vector2i(350, 350))
	var ctx_a := HashingContext.new()
	ctx_a.start(HashingContext.HASH_SHA256)
	ctx_a.update(grid.walkable)
	ctx_a.update(grid.buildable)
	ctx_a.update(grid.movement_cost)
	var hash_a := ctx_a.finish().hex_encode()
	var ctx_b := HashingContext.new()
	ctx_b.start(HashingContext.HASH_SHA256)
	ctx_b.update(grid_b.walkable)
	ctx_b.update(grid_b.buildable)
	ctx_b.update(grid_b.movement_cost)
	if ctx_b.finish().hex_encode() != hash_a:
		print("[semantic-map-regression] FAIL repeat_compile_hash_mismatch")
		quit(1)
		return

	var movement = _MovementAdapter.new(grid.width, grid.height)
	grid.apply_to_movement(movement)
	var walkable: int = grid.count_walkable_cells()
	if walkable < 10000:
		print("[semantic-map-regression] FAIL walkable=%d" % walkable)
		quit(1)
		return
	if grid.walkable.size() != 122500:
		print("[semantic-map-regression] FAIL array_size")
		quit(1)
		return
	if grid.buildable.size() != 122500 or grid.movement_cost.size() != 122500:
		print("[semantic-map-regression] FAIL packed_array_size")
		quit(1)
		return

	var blocker := Image.load_from_file(
		ProjectSettings.globalize_path(
			"res://data/maps/three_lane_swamp_valley/baked/350/07_movement_blocker.png"
		)
	)
	if blocker != null:
		blocker.convert(Image.FORMAT_RGBA8)
		for y in 350:
			for x in 350:
				if blocker.get_pixel(x, y).r8 < 250:
					continue
				if grid.is_walkable_cell(Vector2i(x, y)):
					print("[semantic-map-regression] FAIL blocker_cell_walkable")
					quit(1)
					return

	var path = movement.find_path(Vector2i(175, 300), Vector2i(175, 50))
	if path.is_empty():
		print("[semantic-map-regression] FAIL north_south_path")
		quit(1)
		return

	var metrics := {
		"godot_version": str(Engine.get_version_info().get("string", "")),
		"elapsed_ms": Time.get_ticks_msec() - started_ms,
		"source_native_px": [1254, 1254],
		"compiled_grid_px": [350, 350],
		"cell_count": 122500,
		"walkable_cells": walkable,
		"blocked_cells": 122500 - walkable,
		"buildable_cells": grid.count_buildable_cells(),
		"north_south_path_length": path.size(),
		"compile_fingerprint_sha256": hash_a,
		"swamp_road_overlap": int(validation.get("swamp_overlaps_road_pixels", -1)),
		"road_pixels_not_full_speed": int(validation.get("road_pixels_not_full_speed", -1)),
		"road_pixels_not_no_scatter": int(validation.get("road_pixels_not_no_scatter", -1)),
		"palette_validation": {"pass": true, "source": "import_validation"},
	}
	var artifact := FileAccess.open(
		ProjectSettings.globalize_path(
			"res://data/maps/three_lane_swamp_valley/phase2_regression_artifact.json"
		),
		FileAccess.WRITE,
	)
	if artifact != null:
		artifact.store_string(JSON.stringify(metrics, "\t"))

	print(
		"[semantic-map-regression] ok elapsed_ms=%d walkable=%d path=%d fingerprint=%s overlap=%d"
		% [
			int(metrics["elapsed_ms"]),
			walkable,
			path.size(),
			hash_a,
			int(validation.get("swamp_overlaps_road_pixels", 0)),
		]
	)
	quit(0)
