extends RefCounted

## Phase 5 foliage scatter validation (single static entry — loaded at runtime).

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const ROAD_SAMPLE := Vector2i(175, 200)


static func run() -> Dictionary:
	var Compiler = load("res://scripts/world/map/decorative_scatter_compiler.gd")
	if Compiler == null:
		return _fail("compiler_load_failed")

	var first = Compiler.compile(MAP_ROOT)
	var second = Compiler.compile(MAP_ROOT)
	if first == null or second == null:
		return _fail("compile_failed")

	var chunks_a: int = int(first.stats.get("chunk_count", 0))
	var chunks_b: int = int(second.stats.get("chunk_count", 0))
	var instances_a: int = int(first.stats.get("instance_estimate", 0))
	var instances_b: int = int(second.stats.get("instance_estimate", 0))
	if chunks_a != chunks_b or instances_a != instances_b:
		return _fail("determinism_mismatch chunks=%d/%d instances=%d/%d" % [
			chunks_a, chunks_b, instances_a, instances_b,
		])
	if chunks_a < 10:
		return _fail("too_few_chunks=%d" % chunks_a)
	var grass_cells: int = int(first.stats.get("grass_cells", 0))
	if grass_cells < 5000:
		return _fail("too_few_grass_cells=%d" % grass_cells)

	var road_density: float = first.sample_density(ROAD_SAMPLE)
	if road_density > 0.01:
		return _fail("road_has_grass density=%.3f@%s" % [road_density, ROAD_SAMPLE])

	var log_line := (
		"ok chunks=%d grass=%d instances=%d suppressed=%d"
		% [
			chunks_a,
			grass_cells,
			instances_a,
			int(first.stats.get("scatter_suppressed_cells", 0)),
		]
	)
	return {"ok": true, "log_line": log_line, "foliage": first}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
