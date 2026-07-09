class_name WorldRay
extends RefCounted

## Screen → world helpers for RTS picking on the ground plane (y = 0).


static func ground_hit(camera: Camera3D, screen_pos: Vector2) -> Vector3:
	if camera == null:
		return Vector3.ZERO
	var origin: Vector3 = camera.project_ray_origin(screen_pos)
	var direction: Vector3 = camera.project_ray_normal(screen_pos)
	if absf(direction.y) < 0.0001:
		return Vector3.ZERO
	var t: float = -origin.y / direction.y
	if t < 0.0:
		return Vector3.ZERO
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
