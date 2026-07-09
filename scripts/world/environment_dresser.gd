class_name EnvironmentDresser
extends RefCounted

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")

## Map-edge and camp clutter; snapped to procgen terrain height.


static func populate(root: Node3D, map_width: int, map_height: int) -> void:
	if root == null:
		return
	var w := float(map_width)
	var h := float(map_height)
	var margin := 2.5
	var cx := w * 0.5
	var cz := h * 0.5
	var specs: Array[Dictionary] = [
		{"path": _VisualCatalog.ENV_TREE, "pos": Vector3(margin, 0.0, margin)},
		{"path": _VisualCatalog.ENV_TREE, "pos": Vector3(w - margin, 0.0, margin)},
		{"path": _VisualCatalog.ENV_TREE_PINE, "pos": Vector3(margin, 0.0, h - margin)},
		{"path": _VisualCatalog.ENV_TREE_PINE, "pos": Vector3(w - margin, 0.0, h - margin)},
		{"path": _VisualCatalog.ENV_ROCK, "pos": Vector3(margin + 0.5, 0.0, cz)},
		{"path": _VisualCatalog.ENV_ROCK, "pos": Vector3(w - margin - 0.5, 0.0, cz)},
		{"path": _VisualCatalog.ENV_BUSH, "pos": Vector3(margin + 1.0, 0.0, cz * 0.45)},
		{"path": _VisualCatalog.ENV_BUSH, "pos": Vector3(w - margin - 1.0, 0.0, cz * 1.35)},
		{"path": _VisualCatalog.ENV_GRASS, "pos": Vector3(cx - 4.0, 0.0, cz - 3.0)},
		{"path": _VisualCatalog.ENV_GRASS, "pos": Vector3(cx + 3.5, 0.0, cz + 2.5)},
		{"path": _VisualCatalog.ENV_BARREL, "pos": Vector3(cx - 1.8, 0.0, cz - 2.2)},
		{"path": _VisualCatalog.ENV_CRATE, "pos": Vector3(cx + 0.5, 0.0, cz - 1.5)},
		{"path": _VisualCatalog.ENV_CRATE, "pos": Vector3(cx - 0.5, 0.0, cz + 1.2)},
		{"path": _VisualCatalog.ENV_BARREL, "pos": Vector3(cx + 1.8, 0.0, cz + 0.8)},
	]
	for spec in specs:
		_spawn_prop(root, spec.path, spec.pos)


static func _spawn_prop(root: Node3D, scene_path: String, world_pos: Vector3) -> void:
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		return
	var cell := Vector2i(
		clampi(int(floor(world_pos.x / Constants.TILE_SIZE)), 0, Constants.GRID_WIDTH - 1),
		clampi(int(floor(world_pos.z / Constants.TILE_SIZE)), 0, Constants.GRID_HEIGHT - 1),
	)
	if Services.movement != null:
		if not Services.movement.is_walkable(cell):
			return
		world_pos.y = Services.movement.sample_height_at_cell(cell)
	var scale := _VisualCatalog.env_visual_scale(scene_path)
	_VisualAttacher.spawn_scenery(root, scene_path, world_pos, scale)
