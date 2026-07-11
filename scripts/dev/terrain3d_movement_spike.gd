extends Node3D

## Phase 3 editor scene: visual agent walk + grid overlay on Terrain3D.
## Headless validation uses tests/smoke/test_terrain3d_movement_spike.gd instead.

const AGENT_HALF_HEIGHT := 0.6

@onready var _terrain: Node = $Terrain3D
@onready var _agent: Node3D = $TestAgent
@onready var _overlay: MeshInstance3D = $CompiledGridOverlay
@onready var _results_label: Label = $UI/ResultsLabel
@onready var _grass: Node3D = $AuthoredGrass

var _path: Array[Vector2i] = []
var _path_index := 0
var _path_progress := 0.0
var _agent_speed := 8.0
var _grid = null
var _terrain_node: Node


func _ready() -> void:
	var runner = load("res://scripts/dev/terrain3d_movement_run.gd")
	var result: Dictionary = runner.run(_terrain)
	if _results_label:
		_results_label.text = str(result.get("summary", "failed"))
	if not bool(result.get("ok", false)):
		push_error("[terrain3d-movement-spike] %s" % str(result.get("log_line", "")))
		return
	_grid = result.get("grid")
	var raw_path: Array = result.get("path", [])
	_path.clear()
	for cell in raw_path:
		_path.append(cell)
	_terrain_node = _terrain
	if _overlay and _overlay.has_method("apply_grid") and _grid:
		_overlay.apply_grid(_grid)
	if _agent and not _path.is_empty():
		_agent.global_position = _cell_to_world(_path[0])
	_build_authored_grass(_grid, _path[0] if not _path.is_empty() else Vector2i(175, 175))


func _build_authored_grass(grid, focus_cell: Vector2i) -> void:
	if _grass == null or grid == null:
		return
	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var FoliagePlanner = load("res://scripts/world/foliage/foliage_planner.gd")
	var definition = Factory.load_from_map_root("res://data/maps/three_lane_swamp_valley")
	if definition == null:
		return
	var foliage = FoliagePlanner.plan_from_authored(definition, grid)
	if foliage == null or foliage.chunks.is_empty():
		return
	if _grass.has_method("build_authored"):
		_grass.build_authored(grid, foliage, focus_cell)


func _process(delta: float) -> void:
	if _path.is_empty() or _agent == null:
		return
	if _path_index >= _path.size() - 1:
		return
	_path_progress += delta * _agent_speed
	while _path_progress >= 1.0 and _path_index < _path.size() - 1:
		_path_progress -= 1.0
		_path_index += 1
	var from_cell := _path[_path_index]
	var to_cell := _path[mini(_path_index + 1, _path.size() - 1)]
	_agent.global_position = _cell_to_world(from_cell).lerp(_cell_to_world(to_cell), _path_progress)


func _cell_to_world(cell: Vector2i) -> Vector3:
	var SurfaceAdapter = load("res://scripts/world/terrain/terrain_surface_adapter.gd")
	var xz := Vector3(
		(cell.x + 0.5) * Constants.TILE_SIZE,
		0.0,
		(cell.y + 0.5) * Constants.TILE_SIZE,
	)
	var height := SurfaceAdapter.sample_world_height_from_terrain3d(_terrain_node, xz)
	if is_nan(height) and _grid:
		height = SurfaceAdapter.sample_world_height_from_grid(_grid, xz.x, xz.z)
	xz.y = height + AGENT_HALF_HEIGHT
	return xz
