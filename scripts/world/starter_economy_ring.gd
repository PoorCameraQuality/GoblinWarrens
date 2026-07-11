extends RefCounted

## Guaranteed harvest nodes near the Warren for readable Day 1 gather loops.

const WOOD_MIN_M := 10
const WOOD_MAX_M := 25
const FOOD_MIN_M := 10
const FOOD_MAX_M := 25
const STONE_MIN_M := 15
const STONE_MAX_M := 30


static func ensure(colony: GoblinWarrenColony, warren_cell: Vector2i) -> void:
	if colony == null or warren_cell.x < 0:
		return
	_ensure_kind(colony, warren_cell, Defs.ResourceKind.WOOD, _wood_offsets(), 150)
	_ensure_kind(colony, warren_cell, Defs.ResourceKind.FOOD, _food_offsets(), 80)
	_ensure_kind(colony, warren_cell, Defs.ResourceKind.STONE, _stone_offsets(), 180)


static func _ensure_kind(
	colony: GoblinWarrenColony,
	warren_cell: Vector2i,
	kind: Defs.ResourceKind,
	offsets: Array[Vector2i],
	amount: int,
) -> void:
	if _has_kind_within(colony, warren_cell, kind, _max_radius_for_kind(kind)):
		return
	for offset in offsets:
		var cell := warren_cell + offset
		if colony.try_spawn_starter_resource(cell, kind, amount):
			return


static func _has_kind_within(
	colony: GoblinWarrenColony,
	warren_cell: Vector2i,
	kind: Defs.ResourceKind,
	max_dist: int,
) -> bool:
	for node in colony.get_tree().get_nodes_in_group(Defs.GROUP_RESOURCE_NODE):
		if not node is ResourceNode:
			continue
		var resource := node as ResourceNode
		if resource.resource_kind != kind or not resource.is_available():
			continue
		var dist := _manhattan(warren_cell, resource.grid_cell)
		if dist <= max_dist:
			return true
	return false


static func _max_radius_for_kind(kind: Defs.ResourceKind) -> int:
	match kind:
		Defs.ResourceKind.WOOD:
			return WOOD_MAX_M
		Defs.ResourceKind.FOOD:
			return FOOD_MAX_M
		Defs.ResourceKind.STONE:
			return STONE_MAX_M
		_:
			return 30


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _wood_offsets() -> Array[Vector2i]:
	return [
		Vector2i(14, -10),
		Vector2i(-12, 16),
		Vector2i(18, 12),
		Vector2i(-16, -14),
	]


static func _food_offsets() -> Array[Vector2i]:
	return [
		Vector2i(12, 14),
		Vector2i(-10, -12),
		Vector2i(16, -8),
	]


static func _stone_offsets() -> Array[Vector2i]:
	return [
		Vector2i(20, -14),
		Vector2i(-18, 18),
		Vector2i(22, 16),
	]
