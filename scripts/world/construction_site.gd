class_name ConstructionSite
extends Node3D

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")

## Building placeholder under construction with progress and worker reservation.

signal construction_finished(site: ConstructionSite, building_kind: Defs.BuildingKind)

@export var progress: float = 0.0

var definition: BuildingDef = null
var grid_cell: Vector2i = Vector2i.ZERO
var reserved_by: String = ""
var resources_paid: bool = false
var placement_yaw: float = 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_CONSTRUCTION)


func setup(cell: Vector2i, def: BuildingDef, paid: bool, yaw: float = 0.0) -> void:
	definition = def
	grid_cell = cell
	resources_paid = paid
	placement_yaw = yaw
	progress = 0.0
	rotation.y = yaw
	if Services.movement != null:
		position = Services.movement.footprint_center_world(cell, def.footprint)
	else:
		position = Vector3(
			(cell.x + def.footprint.x * 0.5) * Constants.TILE_SIZE,
			0.0,
			(cell.y + def.footprint.y * 0.5) * Constants.TILE_SIZE,
		)
	_update_visual()


func is_complete() -> bool:
	return progress >= 1.0


func is_reserved_by(other_id: String) -> bool:
	return not reserved_by.is_empty() and reserved_by != other_id


func try_reserve(worker_id: String) -> bool:
	if is_complete() or not resources_paid:
		return false
	if is_reserved_by(worker_id):
		return false
	reserved_by = worker_id
	return true


func release_reservation(worker_id: String) -> void:
	if reserved_by == worker_id:
		reserved_by = ""


func add_build_progress(amount: float) -> void:
	progress = clampf(progress + amount, 0.0, 1.0)
	_update_visual()
	if is_complete():
		construction_finished.emit(self, definition.kind)


func interaction_cell(movement: MovementAdapter) -> Vector2i:
	var edge: Vector2i = grid_cell + Vector2i(-1, 0)
	return movement.nearest_reachable(edge, grid_cell)


func footprint_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if definition == null:
		return cells
	for dx in range(definition.footprint.x):
		for dy in range(definition.footprint.y):
			cells.append(grid_cell + Vector2i(dx, dy))
	return cells


func _update_visual() -> void:
	var mesh: CSGBox3D = get_node_or_null("Mesh") as CSGBox3D
	if mesh == null or definition == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.7, 0.75, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh.material = mat
	var height: float = 0.3 + progress * 1.0
	mesh.size = Vector3(
		definition.footprint.x * 0.9,
		height,
		definition.footprint.y * 0.9,
	)
	mesh.position = Vector3(0.0, height * 0.5, 0.0)
	_sync_build_art()


func _sync_build_art() -> void:
	if definition == null:
		return
	var path: String = _VisualCatalog.building_wrapper(definition.kind)
	var art := get_node_or_null("ArtVisual") as Node3D
	if art == null:
		var base_scale := _VisualCatalog.building_visual_scale(definition.kind, path)
		art = _VisualAttacher.try_attach(self, path, ["Mesh"], base_scale)
	if art == null:
		return
	var base_scale := _VisualCatalog.building_visual_scale(definition.kind, path)
	var y_scale: float = 0.25 + progress * 0.75
	art.scale = Vector3(base_scale.x, base_scale.y * y_scale, base_scale.z)
	art.position = Vector3(0.0, y_scale * 0.4 * base_scale.y, 0.0)
	var mesh: CSGBox3D = get_node_or_null("Mesh") as CSGBox3D
	if mesh != null:
		mesh.visible = false
