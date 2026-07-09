class_name Building
extends Node3D

## Completed structure on the colony grid.

@export var building_kind: Defs.BuildingKind = Defs.BuildingKind.STOREHOUSE
@export var display_name: String = "Building"

var grid_cell: Vector2i = Vector2i.ZERO
var footprint: Vector2i = Vector2i(1, 1)


func _ready() -> void:
	add_to_group(Defs.GROUP_BUILDING)


func setup(cell: Vector2i, def: BuildingDef, yaw: float = 0.0) -> void:
	grid_cell = cell
	building_kind = def.kind
	display_name = def.display_name
	footprint = def.footprint
	rotation.y = yaw
	position = _footprint_center(cell, footprint)
	BuildingFactory.attach_visual(self, def.kind)
	_apply_visual(def.kind)


func occupies_cell(cell: Vector2i) -> bool:
	for dx in range(footprint.x):
		for dy in range(footprint.y):
			if grid_cell + Vector2i(dx, dy) == cell:
				return true
	return false


func interaction_cell(movement: MovementAdapter) -> Vector2i:
	var edge: Vector2i = grid_cell + Vector2i(-1, 0)
	return movement.nearest_reachable(edge, grid_cell)


func _footprint_center(cell: Vector2i, size: Vector2i) -> Vector3:
	if Services.movement != null:
		return Services.movement.footprint_center_world(cell, size)
	var center := Vector2(cell) + Vector2(size) * 0.5
	return Vector3(center.x * Constants.TILE_SIZE, 0.0, center.y * Constants.TILE_SIZE)


func _apply_visual(kind: Defs.BuildingKind) -> void:
	var mesh: CSGBox3D = get_node_or_null("Mesh") as CSGBox3D
	if mesh == null:
		return
	var mat := StandardMaterial3D.new()
	match kind:
		Defs.BuildingKind.STOREHOUSE:
			mat.albedo_color = Color(0.45, 0.32, 0.18)
			mesh.size = Vector3(1.8, 1.2, 1.8)
		Defs.BuildingKind.LUMBER_HUT:
			mat.albedo_color = Color(0.35, 0.25, 0.12)
			mesh.size = Vector3(1.6, 1.0, 1.6)
		Defs.BuildingKind.GOLD_MINE:
			mat.albedo_color = Color(0.5, 0.42, 0.15)
			mesh.size = Vector3(1.6, 1.4, 1.6)
		Defs.BuildingKind.QUARRY:
			mat.albedo_color = Color(0.4, 0.4, 0.42)
			mesh.size = Vector3(1.8, 0.8, 1.8)
		Defs.BuildingKind.SLEEPING_PIT:
			mat.albedo_color = Color(0.32, 0.28, 0.35)
			mesh.size = Vector3(1.8, 0.5, 1.8)
		Defs.BuildingKind.WARREN:
			mat.albedo_color = Color(0.38, 0.22, 0.15)
			mesh.size = Vector3(2.2, 1.4, 2.2)
		Defs.BuildingKind.FORAGER_POST:
			mat.albedo_color = Color(0.28, 0.42, 0.22)
			mesh.size = Vector3(1.4, 1.0, 1.4)
		Defs.BuildingKind.MUSHROOM_FARM:
			mat.albedo_color = Color(0.45, 0.3, 0.55)
			mesh.size = Vector3(1.6, 0.8, 1.6)
		Defs.BuildingKind.BREEDER_HUT:
			mat.albedo_color = Color(0.42, 0.28, 0.32)
			mesh.size = Vector3(1.8, 1.1, 1.8)
		Defs.BuildingKind.SHRINE:
			mat.albedo_color = Color(0.55, 0.45, 0.2)
			mesh.size = Vector3(1.6, 1.6, 1.6)
		Defs.BuildingKind.GUARD_POST:
			mat.albedo_color = Color(0.35, 0.35, 0.38)
			mesh.size = Vector3(1.2, 1.4, 1.2)
		Defs.BuildingKind.WATCHTOWER:
			mat.albedo_color = Color(0.4, 0.32, 0.22)
			mesh.size = Vector3(1.0, 2.4, 1.0)
		Defs.BuildingKind.BURIAL_GROUNDS:
			mat.albedo_color = Color(0.25, 0.25, 0.28)
			mesh.size = Vector3(2.0, 0.4, 2.0)
		Defs.BuildingKind.BARRACKS:
			mat.albedo_color = Color(0.35, 0.28, 0.24)
			mesh.size = Vector3(2.0, 1.4, 2.0)
		Defs.BuildingKind.BLACKSMITH:
			mat.albedo_color = Color(0.30, 0.25, 0.30)
			mesh.size = Vector3(1.8, 1.4, 1.8)
		Defs.BuildingKind.COOK_HUT:
			mat.albedo_color = Color(0.45, 0.34, 0.22)
			mesh.size = Vector3(1.8, 1.2, 1.8)
		Defs.BuildingKind.SHAMAN_HUT:
			mat.albedo_color = Color(0.42, 0.28, 0.48)
			mesh.size = Vector3(1.8, 1.6, 1.8)
		_:
			mat.albedo_color = Color(0.5, 0.5, 0.5)
	mesh.material = mat
