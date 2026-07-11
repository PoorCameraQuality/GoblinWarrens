class_name MapEdgeBarrier
extends RefCounted

## Decorative mountain ring at the playable map rim (visual barrier only).

const BORDER_INSET_CELLS := 5 ## meters from map edge toward interior
const SPACING_M := 16.0 ## average gap between peaks along an edge
const SCALE_MIN := 2.8
const SCALE_MAX := 4.6
const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")
const _WorldSurface := preload("res://scripts/world/world_surface.gd")


static func spawn(parent: Node3D, map_width: int, map_height: int, seed: int = 424242) -> int:
	if parent == null or map_width <= 0 or map_height <= 0:
		return 0
	var models: Array[String] = _VisualCatalog.border_mountain_paths()
	if models.is_empty():
		return 0
	var count := 0
	var inset := float(BORDER_INSET_CELLS)
	var max_x := float(map_width - 1) - inset
	var max_z := float(map_height - 1) - inset
	var min_x := inset
	var min_z := inset

	# South edge (z = min)
	count += _spawn_edge(
		parent, models, seed, Vector2(min_x, min_z), Vector2(max_x, min_z), SPACING_M, 0.0
	)
	# North edge (z = max)
	count += _spawn_edge(
		parent, models, seed + 101, Vector2(min_x, max_z), Vector2(max_x, max_z), SPACING_M, PI
	)
	# West edge (x = min)
	count += _spawn_edge(
		parent, models, seed + 202, Vector2(min_x, min_z), Vector2(min_x, max_z), SPACING_M, PI * 0.5
	)
	# East edge (x = max)
	count += _spawn_edge(
		parent, models, seed + 303, Vector2(max_x, min_z), Vector2(max_x, max_z), SPACING_M, -PI * 0.5
	)
	return count


static func _spawn_edge(
	parent: Node3D,
	models: Array[String],
	seed: int,
	start: Vector2,
	end: Vector2,
	spacing: float,
	base_yaw: float,
) -> int:
	var delta := end - start
	var length := delta.length()
	if length < spacing * 0.5:
		return 0
	var steps := maxi(1, int(floor(length / spacing)))
	var placed := 0
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var jitter := (_hash01(i, seed) - 0.5) * spacing * 0.35
		var pos2 := start.lerp(end, t) + delta.orthogonal().normalized() * jitter * 0.02
		var world_x := pos2.x * Constants.TILE_SIZE
		var world_z := pos2.y * Constants.TILE_SIZE
		var path: String = models[_hash_index(i, seed, models.size())]
		var scale_factor := lerpf(SCALE_MIN, SCALE_MAX, _hash01(i + 17, seed + 7))
		var yaw := base_yaw + (_hash01(i + 3, seed + 11) - 0.5) * 0.6
		var world := _WorldSurface.snap_world_position(Vector3(world_x, 0.0, world_z))
		var instance := _VisualAttacher.spawn_scenery(
			parent,
			path,
			world,
			Vector3.ONE * scale_factor,
		)
		if instance != null:
			instance.rotation.y = yaw
			placed += 1
	return placed


static func _hash01(x: int, seed: int) -> float:
	var n := seed * 374761393 + x * 668265263
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7fffffff) / 2147483647.0


static func _hash_index(x: int, seed: int, count: int) -> int:
	if count <= 0:
		return 0
	return int(_hash01(x + 29, seed + 53) * float(count)) % count
