class_name WorldRay
extends RefCounted

const _WorldSurface := preload("res://scripts/world/world_surface.gd")

## Screen → world helpers for RTS picking on terrain.


static func ground_hit(camera: Camera3D, screen_pos: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var origin: Vector3 = camera.project_ray_origin(screen_pos)
	var direction: Vector3 = camera.project_ray_normal(screen_pos)
	if direction.length_squared() < 0.0001:
		return Vector3.ZERO
	direction = direction.normalized()
	var viewport := camera.get_viewport()
	if viewport != null:
		var space := viewport.get_world_3d().direct_space_state
		if space != null:
			var to: Vector3 = origin + direction * 2500.0
			var query := PhysicsRayQueryParameters3D.create(origin, to)
			query.collide_with_areas = false
			query.collide_with_bodies = true
			var hit: Dictionary = space.intersect_ray(query)
			if not hit.is_empty():
				return hit.position
	return _WorldSurface.snap_world_position(_plane_hit_at_y0(origin, direction))


static func _plane_hit_at_y0(origin: Vector3, direction: Vector3) -> Vector3:
	if absf(direction.y) < 0.0001:
		return Vector3(origin.x, 0.0, origin.z)
	var t: float = -origin.y / direction.y
	if t < 0.0:
		return Vector3(origin.x, 0.0, origin.z)
	return origin + direction * t


static func closest_goblin(
	camera: Camera3D,
	screen_pos: Vector2,
	goblins_root: Node
) -> Goblin:
	if camera == null or goblins_root == null:
		return null
	var best: Goblin = null
	var best_dist: float = Constants.PICK_UNIT_SCREEN_RADIUS
	for child in goblins_root.get_children():
		if not child is Goblin:
			continue
		var goblin := child as Goblin
		if not camera.is_position_behind(goblin.global_position):
			var screen: Vector2 = camera.unproject_position(goblin.global_position)
			var dist: float = screen.distance_to(screen_pos)
			if dist <= best_dist:
				best_dist = dist
				best = goblin
	return best


static func goblins_in_screen_rect(
	camera: Camera3D,
	rect: Rect2,
	goblins_root: Node
) -> Array[Goblin]:
	var result: Array[Goblin] = []
	if camera == null or goblins_root == null:
		return result
	var normalized := Rect2(
		minf(rect.position.x, rect.end.x),
		minf(rect.position.y, rect.end.y),
		absf(rect.size.x),
		absf(rect.size.y),
	)
	for child in goblins_root.get_children():
		if not child is Goblin:
			continue
		var goblin := child as Goblin
		if camera.is_position_behind(goblin.global_position):
			continue
		var screen: Vector2 = camera.unproject_position(goblin.global_position)
		if normalized.has_point(screen):
			result.append(goblin)
	return result
