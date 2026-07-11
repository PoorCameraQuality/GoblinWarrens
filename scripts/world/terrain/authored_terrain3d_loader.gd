extends RefCounted

## Loads authored map height into a Terrain3D node (Phase 3).
## Single entry function — see docs/technical/GODOT_HEADLESS_PITFALLS.md.


static func ensure_loaded(terrain: Node, map_root: String, grid_size: Vector2i) -> Dictionary:
	var result := {"ok": false, "errors": PackedStringArray(), "data_dir": ""}
	if terrain == null or not terrain.is_class("Terrain3D"):
		result["errors"].append("terrain_node_invalid")
		return result
	if not ClassDB.class_exists("Terrain3D"):
		result["errors"].append("terrain3d_extension_missing")
		return result

	var data_dir := map_root.path_join("terrain3d_data")
	result["data_dir"] = data_dir
	terrain.set("data_directory", data_dir)
	terrain.set("vertex_spacing", 1.0)

	if terrain.get("material") == null:
		terrain.set("material", ClassDB.instantiate("Terrain3DMaterial"))
	if terrain.get("assets") == null:
		var assets: Object = ClassDB.instantiate("Terrain3DAssets")
		var mesh_asset: Object = ClassDB.instantiate("Terrain3DMeshAsset")
		mesh_asset.set("generated_type", 1)
		mesh_asset.set("density", 2.0)
		assets.call("set_mesh_asset", 0, mesh_asset)
		terrain.set("assets", assets)

	var terrain_data: Object = terrain.get("data")
	if terrain_data == null:
		result["errors"].append("terrain_data_null")
		return result

	var global_data := ProjectSettings.globalize_path(data_dir)
	if DirAccess.dir_exists_absolute(global_data):
		terrain_data.call("load_directory", data_dir)
		if int(terrain_data.call("get_region_count")) > 0:
			result["ok"] = true
			return result

	var height_path := _abs(
		map_root.path_join("baked").path_join("%d" % grid_size.x).path_join("01_heightmap.png")
	)
	if not FileAccess.file_exists(height_path):
		result["errors"].append("missing_baked_heightmap")
		return result

	var source := Image.load_from_file(height_path)
	if source == null:
		result["errors"].append("failed_load_heightmap")
		return result
	source.convert(Image.FORMAT_RGBA8)

	var rf := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RF)
	for y in grid_size.y:
		for x in grid_size.x:
			var meters := source.get_pixel(x, y).r * Constants.MAPGEN_HEIGHT_SCALE
			rf.set_pixel(x, y, Color(meters, 0.0, 0.0, 1.0))

	var type_max: int = ClassDB.class_get_integer_constant("Terrain3DRegion", "TYPE_MAX")
	var type_height: int = ClassDB.class_get_integer_constant("Terrain3DRegion", "TYPE_HEIGHT")
	var images: Array = []
	images.resize(type_max)
	images[type_height] = rf
	terrain_data.call("import_images", images, Vector3.ZERO, 0.0, 1.0)
	terrain_data.call("calc_height_range", true)

	DirAccess.make_dir_recursive_absolute(global_data)
	terrain_data.call("save_directory", data_dir)
	terrain_data.call("load_directory", data_dir)

	if int(terrain_data.call("get_region_count")) <= 0:
		result["errors"].append("terrain_import_no_regions")
		return result

	result["ok"] = true
	return result


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)
