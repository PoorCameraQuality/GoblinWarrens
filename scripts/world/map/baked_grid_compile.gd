extends RefCounted

## Compiles baked semantic layers into CompiledGridMap (Phase 2).
##
## STABILITY NOTE (intentional technical debt):
## This compiler is intentionally kept in one function because the Godot 4.7
## GDScript analyzer exhibited repeatable stalls when the same logic was
## distributed across typed helper functions and sibling scripts. Do not
## refactor without running the semantic-map headless regression suite before
## and after each change:
##   godot --headless --path . --script tests/smoke/test_semantic_map_regression.gd
## See docs/technical/GODOT_HEADLESS_PITFALLS.md for why this shape is required.

const BLOCKER_THRESHOLD := 250
const BUILDABLE_THRESHOLD := 128
const COLOR_MATCH_TOLERANCE := 0.02


static func compile(map_root: String, target_size: Vector2i) -> Variant:
	var manifest_path := ProjectSettings.globalize_path(map_root.path_join("manifest.json"))
	if not FileAccess.file_exists(manifest_path):
		return null
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if manifest.is_empty():
		return null

	var baked_dir := map_root.path_join("baked").path_join("%d" % target_size.x)
	var files: Dictionary = manifest.get("files", {})
	var layer_files := {
		"heightmap": str(files.get("heightmap", "")),
		"terrain_classes": str(files.get("project_terrain_classes", "")),
		"buildability": str(files.get("buildability", "")),
		"movement_blocker": str(files.get("movement_blocker", "")),
		"movement_cost": str(files.get("movement_cost", "")),
	}
	var layers: Dictionary = {}
	for key: String in layer_files.keys():
		var file_name: String = layer_files[key]
		if file_name.is_empty():
			return null
		var image := Image.load_from_file(ProjectSettings.globalize_path(baked_dir.path_join(file_name)))
		if image == null:
			return null
		image.convert(Image.FORMAT_RGBA8)
		layers[key] = image

	var width := target_size.x
	var height := target_size.y
	var grid = load("res://scripts/world/map/compiled_grid_map.gd").new()
	grid.map_id = str(manifest.get("map_id", ""))
	grid.display_name = str(manifest.get("display_name", ""))
	grid.width = width
	grid.height = height

	var point_w := width + 1
	var point_h := height + 1
	var heights := PackedFloat32Array()
	heights.resize(point_w * point_h)
	var min_h := INF
	var max_h := -INF
	var heightmap: Image = layers["heightmap"]
	for z in range(point_h):
		for x in range(point_w):
			var gray := heightmap.get_pixel(clampi(x, 0, width - 1), clampi(z, 0, height - 1)).r
			var meters := gray * Constants.MAPGEN_HEIGHT_SCALE
			heights[z * point_w + x] = meters
			min_h = minf(min_h, meters)
			max_h = maxf(max_h, meters)
	grid.heights = heights
	grid.height_point_width = point_w
	grid.height_point_height = point_h
	grid.height_min = min_h
	grid.height_max = max_h
	grid.walkable.resize(width * height)
	grid.buildable.resize(width * height)
	grid.movement_cost.resize(width * height)

	var palette: Dictionary = manifest.get("project_terrain_class_palette", {})
	var terrain_img: Image = layers["terrain_classes"]
	var blocker_img: Image = layers["movement_blocker"]
	var build_img: Image = layers["buildability"]
	var cost_img: Image = layers["movement_cost"]

	for y in range(height):
		var row: Array = []
		row.resize(width)
		for x in range(width):
			var pixel := terrain_img.get_pixel(x, y)
			var terrain_class := Defs.TerrainClass.MOSS
			for hex: String in palette.keys():
				var color := Color.from_string(hex, Color.MAGENTA)
				if (
					absf(pixel.r - color.r) <= COLOR_MATCH_TOLERANCE
					and absf(pixel.g - color.g) <= COLOR_MATCH_TOLERANCE
					and absf(pixel.b - color.b) <= COLOR_MATCH_TOLERANCE
				):
					terrain_class = _class_for_name(str(palette[hex]))
					break
			row[x] = terrain_class
			var blocked := blocker_img.get_pixel(x, y).r8 >= BLOCKER_THRESHOLD
			var walkable := not blocked
			var buildable := walkable and build_img.get_pixel(x, y).r8 >= BUILDABLE_THRESHOLD
			var cost := int(cost_img.get_pixel(x, y).r8)
			if not walkable:
				cost = 255
			var index := y * width + x
			grid.walkable[index] = 1 if walkable else 0
			grid.buildable[index] = 1 if buildable else 0
			grid.movement_cost[index] = cost
		grid.tile_classes.append(row)
	return grid


static func _class_for_name(terrain_name: String) -> int:
	match terrain_name:
		"MUD_CLEARING": return Defs.TerrainClass.MUD_CLEARING
		"MOSS": return Defs.TerrainClass.MOSS
		"FOREST_FLOOR": return Defs.TerrainClass.FOREST_FLOOR
		"ROCKY_SLOPE": return Defs.TerrainClass.ROCKY_SLOPE
		"MUD_MOSSY": return Defs.TerrainClass.MUD_MOSSY
		"CLIFF": return Defs.TerrainClass.CLIFF
		"WARREN_GROUND": return Defs.TerrainClass.WARREN_GROUND
		_: return Defs.TerrainClass.MOSS
