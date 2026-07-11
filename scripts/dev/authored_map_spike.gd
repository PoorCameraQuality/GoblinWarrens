extends Node3D

## Dev spike: compile Three-Lane Swamp Valley semantic layers and preview grid overlay.
## Does not modify colony gameplay. See docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md Phase 2.

const _GridCompiler := preload("res://scripts/world/map/grid_compiler.gd")
const _MovementAdapter := preload("res://scripts/agents/movement_adapter.gd")
const _SurfaceAdapter := preload("res://scripts/world/terrain/terrain_surface_adapter.gd")

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"

@onready var _overlay: MeshInstance3D = $CompiledGridOverlay
@onready var _results_label: Label = $UI/ResultsLabel


func _ready() -> void:
	var grid = _GridCompiler.compile_map(MAP_ROOT, Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT))
	if grid == null:
		_show_failure("Grid compile failed — run tools/import_semantic_map.gd first")
		return

	var movement = _MovementAdapter.new(grid.width, grid.height)
	grid.apply_to_movement(movement)
	var path := movement.find_path(Vector2i(175, 300), Vector2i(175, 50))
	var center_height := _SurfaceAdapter.sample_grid_height(grid, Vector2i(175, 175))
	var summary := (
		"Authored map grid spike\n"
		+ "  map=%s\n" % grid.display_name
		+ "  walkable=%d buildable=%d\n" % [grid.count_walkable_cells(), grid.count_buildable_cells()]
		+ "  height_range=%.1f-%.1f m\n" % [grid.height_min, grid.height_max]
		+ "  center_height=%.1f m\n" % center_height
		+ "  north_south_path_len=%d\n" % path.size()
	)
	_results_label.text = summary
	Log.info("grid_compiler_spike", summary.replace("\n", " | "))

	if _overlay and _overlay.has_method("apply_grid"):
		_overlay.apply_grid(grid)

	if _should_auto_quit():
		var ok := not path.is_empty() and grid.count_walkable_cells() > 10000
		print("[grid-compiler-spike] ok=%s path=%d walkable=%d" % [ok, path.size(), grid.count_walkable_cells()])
		get_tree().call_deferred("quit", 0 if ok else 1)


static func _should_auto_quit() -> bool:
	return OS.has_feature("server") or DisplayServer.get_name() == "headless"


func _show_failure(message: String) -> void:
	push_error("[grid-compiler-spike] %s" % message)
	if _results_label:
		_results_label.text = message
	if _should_auto_quit():
		get_tree().call_deferred("quit", 1)
