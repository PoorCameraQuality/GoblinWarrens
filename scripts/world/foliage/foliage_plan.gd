class_name FoliagePlan
extends RefCounted

## Deterministic grass + ambient-life plan produced by FoliagePlanner.
## Visual only — never feeds MovementAdapter / pathfinding.

enum GrassStyle {
	NONE = 0,
	SHORT_MOSS = 1,
	SHADE_SPARSE = 2,
	WET_REED = 3,
	DRY_TUFT = 4,
}

enum AmbientEffect {
	BUTTERFLIES = 0,
	FIREFLIES = 1,
	GNATS = 2,
	SPORES = 3,
}

var width: int = 0
var height: int = 0
var chunk_size: int = 16 ## tiles (= meters at TILE_SIZE 1)
var density: PackedFloat32Array = PackedFloat32Array() ## 0–1 per cell
var style_ids: PackedByteArray = PackedByteArray() ## GrassStyle per cell
var chunks: Array = [] ## Array[Dictionary]
var ambient_zones: Array = [] ## Array[Dictionary]
var stats: Dictionary = {}
## Runtime suppress set (building footprints punched after generation).
var suppressed_cells: Dictionary = {} ## Vector2i -> true
## Cached blockers from prop scatter for probe_density.
var blocker_cells: Dictionary = {}


func cell_index(cell: Vector2i) -> int:
	return cell.y * width + cell.x


func sample_density(cell: Vector2i) -> float:
	if suppressed_cells.has(cell):
		return 0.0
	if density.is_empty():
		return 0.0
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return 0.0
	var idx := cell_index(cell)
	if idx < 0 or idx >= density.size():
		return 0.0
	return density[idx]


func sample_style(cell: Vector2i) -> int:
	if suppressed_cells.has(cell):
		return GrassStyle.NONE
	if style_ids.is_empty():
		return GrassStyle.NONE
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return GrassStyle.NONE
	var idx := cell_index(cell)
	if idx < 0 or idx >= style_ids.size():
		return GrassStyle.NONE
	return int(style_ids[idx])


func suppress_cells(cells: Array) -> void:
	for entry in cells:
		var cell: Vector2i = entry
		suppressed_cells[cell] = true
