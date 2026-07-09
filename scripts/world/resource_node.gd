class_name ResourceNode
extends Node3D

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")

## Gatherable world node: gold vein, tree, or stone pile.

@export var resource_kind: Defs.ResourceKind = Defs.ResourceKind.WOOD
@export var total_amount: int = 100
@export var gather_per_action: int = Constants.GATHER_AMOUNT

var remaining: int = 0
var reserved_by: String = ""
var grid_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	add_to_group(Defs.GROUP_RESOURCE_NODE)
	if remaining <= 0:
		remaining = total_amount
	_apply_visual()


func setup(cell: Vector2i, kind: Defs.ResourceKind, amount: int) -> void:
	grid_cell = cell
	resource_kind = kind
	total_amount = amount
	remaining = amount
	position = _world_from_cell(cell)
	_apply_visual()


func is_available() -> bool:
	return remaining > 0


func is_reserved_by(other_id: String) -> bool:
	return not reserved_by.is_empty() and reserved_by != other_id


func try_reserve(worker_id: String) -> bool:
	if not is_available():
		return false
	if is_reserved_by(worker_id):
		return false
	reserved_by = worker_id
	return true


func release_reservation(worker_id: String) -> void:
	if reserved_by == worker_id:
		reserved_by = ""


func gather(amount: int) -> int:
	var taken: int = mini(amount, remaining)
	remaining -= taken
	if remaining <= 0:
		release_reservation(reserved_by)
		_set_depleted_visual()
	return taken


func interaction_cell(movement: MovementAdapter) -> Vector2i:
	return movement.nearest_reachable(grid_cell, grid_cell)


func _apply_visual() -> void:
	var mesh: CSGBox3D = get_node_or_null("Mesh") as CSGBox3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	match resource_kind:
		Defs.ResourceKind.GOLD:
			mat.albedo_color = Color(0.85, 0.72, 0.2)
		Defs.ResourceKind.WOOD:
			mat.albedo_color = Color(0.25, 0.55, 0.2)
		Defs.ResourceKind.STONE:
			mat.albedo_color = Color(0.55, 0.55, 0.58)
		Defs.ResourceKind.FOOD:
			mat.albedo_color = Color(0.65, 0.45, 0.2)
	mesh.material = mat
	var path: String = _VisualCatalog.resource_wrapper(resource_kind)
	var scale := _VisualCatalog.resource_visual_scale(path)
	_VisualAttacher.try_attach(self, path, ["Mesh"], scale)


func _set_depleted_visual() -> void:
	var mesh: CSGBox3D = get_node_or_null("Mesh") as CSGBox3D
	if mesh:
		mesh.scale = Vector3(0.6, 0.2, 0.6)
	var art := get_node_or_null("ArtVisual") as Node3D
	if art:
		art.scale = Vector3(0.5, 0.5, 0.5)


func _world_from_cell(cell: Vector2i) -> Vector3:
	if Services.movement != null:
		return Services.movement.grid_to_world(cell)
	return Vector3(
		(cell.x + 0.5) * Constants.TILE_SIZE,
		0.0,
		(cell.y + 0.5) * Constants.TILE_SIZE,
	)
