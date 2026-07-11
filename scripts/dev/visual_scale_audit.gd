class_name VisualScaleAudit
extends RefCounted

## Debug-only expected sizes vs measured AABB for MVP visuals.

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")

static func run() -> String:
	var lines: PackedStringArray = PackedStringArray()
	for sample in _samples():
		lines.append(_audit_sample(sample))
	return "\n".join(lines)


static func _samples() -> Array[Dictionary]:
	return [
		{"key": "BUILDING_WARREN", "path": _VisualCatalog.BUILDING_WARREN, "scale": _VisualCatalog.building_visual_scale(Defs.BuildingKind.WARREN), "min_m": 7.0, "max_m": 9.0, "axis": "xz"},
		{"key": "BUILDING_SHRINE", "path": _VisualCatalog.BUILDING_SHRINE, "scale": _VisualCatalog.building_visual_scale(Defs.BuildingKind.SHRINE), "min_m": 8.0, "max_m": 10.0, "axis": "xz"},
		{"key": "BUILDING_SLEEPING_PIT", "path": _VisualCatalog.BUILDING_SLEEPING_PIT, "scale": _VisualCatalog.building_visual_scale(Defs.BuildingKind.SLEEPING_PIT), "min_m": 3.5, "max_m": 4.5, "axis": "xz"},
		{"key": "BUILDING_WATCHTOWER", "path": _VisualCatalog.BUILDING_WATCHTOWER, "scale": _VisualCatalog.building_visual_scale(Defs.BuildingKind.WATCHTOWER), "min_m": 3.5, "max_m": 4.5, "axis": "xz"},
		{"key": "GOBLIN_WORKER", "path": _VisualCatalog.GOBLIN_WORKER, "scale": _VisualCatalog.unit_visual_scale(false, false, false), "min_m": 1.0, "max_m": 1.15, "axis": "y"},
		{"key": "GOBLIN_FOBLIN", "path": _VisualCatalog.GOBLIN_FOBLIN, "scale": _VisualCatalog.unit_visual_scale(true, false, false), "min_m": 0.75, "max_m": 0.95, "axis": "y"},
		{"key": "ENEMY_SCOUT", "path": _VisualCatalog.ENEMY_SCOUT, "scale": _VisualCatalog.enemy_visual_scale(Defs.EnemyKind.SCOUT), "min_m": 1.6, "max_m": 2.0, "axis": "y"},
		{"key": "ENV_TREE_BIRCH", "path": _VisualCatalog.ENV_TREE, "scale": _VisualCatalog.env_visual_scale(_VisualCatalog.ENV_TREE), "min_m": 2.5, "max_m": 3.5, "axis": "y"},
		{"key": "ENV_TREE_PINE", "path": _VisualCatalog.ENV_TREE_PINE, "scale": _VisualCatalog.env_visual_scale(_VisualCatalog.ENV_TREE_PINE), "min_m": 3.5, "max_m": 4.5, "axis": "y"},
		{"key": "ENV_ROCK", "path": _VisualCatalog.ENV_ROCK, "scale": _VisualCatalog.env_visual_scale(_VisualCatalog.ENV_ROCK), "min_m": 1.0, "max_m": 2.2, "axis": "y"},
	]


static func _audit_sample(sample: Dictionary) -> String:
	var key: String = sample.key
	var path: String = sample.path
	var scale: Vector3 = sample.scale
	var min_m: float = sample.min_m
	var max_m: float = sample.max_m
	var axis: String = sample.axis
	if not ResourceLoader.exists(path):
		return "%s FAIL missing path %s" % [key, path]
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return "%s FAIL load failed %s" % [key, path]
	var root: Node3D = packed.instantiate() as Node3D
	if root == null:
		return "%s FAIL instantiate failed %s" % [key, path]
	var has_model := root.get_node_or_null("Model") != null
	var root_name := root.name
	root.scale = scale
	var aabb := _mesh_aabb(root)
	root.free()
	var measured := _measure_axis(aabb, axis, scale)
	var status := "PASS" if measured >= min_m and measured <= max_m else "FAIL"
	return (
		"%s %s path=%s root=%s model=%s scale=%s measured=%.2fm expected=%.1f-%.1f"
		% [key, status, path, root_name, "yes" if has_model else "no", str(scale), measured, min_m, max_m]
	)


static func _measure_axis(aabb: AABB, axis: String, scale: Vector3) -> float:
	match axis:
		"y":
			return aabb.size.y * scale.y
		"x":
			return aabb.size.x * scale.x
		"z":
			return aabb.size.z * scale.z
		_:
			return maxf(aabb.size.x * scale.x, aabb.size.z * scale.z)


static func _mesh_aabb(root: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [root]
	while stack.size() > 0:
		var node = stack.pop_back()
		if node is MeshInstance3D:
			var mi: MeshInstance3D = node
			var local_aabb: AABB = mi.get_aabb()
			if first:
				out = local_aabb
				first = false
			else:
				out = out.merge(local_aabb)
		for child in node.get_children():
			stack.push_back(child)
	return out
