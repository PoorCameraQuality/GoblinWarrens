extends RefCounted

const _Core := preload("res://scripts/world/map/baked_grid_compile.gd")


static func compile_map(map_root: String, target_size: Vector2i) -> Variant:
	return _Core.compile(map_root, target_size)
