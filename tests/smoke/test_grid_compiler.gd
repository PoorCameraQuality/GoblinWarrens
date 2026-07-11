extends SceneTree

## Headless smoke test for Phase 2 grid compiler + movement integration.
## godot --headless --path . --script tests/smoke/test_grid_compiler.gd

const _Compiler := preload("res://scripts/world/map/grid_compiler.gd")
const _MovementAdapter := preload("res://scripts/agents/movement_adapter.gd")
const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


func _init() -> void:
	var grid = _Compiler.compile_map(MAP_ROOT, Vector2i(350, 350))
	if grid == null:
		push_error("[grid-compiler-smoke] compile failed")
		quit(1)
		return

	var movement = _MovementAdapter.new(grid.width, grid.height)
	grid.apply_to_movement(movement)
	var walkable: int = grid.count_walkable_cells()
	if walkable < 10000:
		push_error("[grid-compiler-smoke] too few walkable cells=%d" % walkable)
		quit(1)
		return

	var path = movement.find_path(Vector2i(175, 300), Vector2i(175, 50))
	if path.is_empty():
		push_error("[grid-compiler-smoke] no north-south path")
		quit(1)
		return

	var center_height: float = grid.sample_height_at_cell(Vector2i(175, 175))
	print(
		"[grid-compiler-smoke] ok map=%s walkable=%d buildable=%d path=%d height=%.1f"
		% [grid.map_id, walkable, grid.count_buildable_cells(), path.size(), center_height]
	)
	quit(0)
