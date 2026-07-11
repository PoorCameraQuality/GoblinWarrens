extends RefCounted

## Post-bake edge treatment for authored maps — procgen-style enclosing hills.
## Uplifts heightmap edges, marks impassable cliff band, blocks scatter.

const BORDER_UPLIFT_DEPTH := 10 ## cells; height uplift + impassable band
const BORDER_SCATTER_DEPTH := 7 ## cells; no_scatter ring (matches procgen BORDER_DEPTH)
const CLIFF_HEX := "#8A2BE2"
const BLOCKER_VALUE := 255
const NO_SCATTER_VALUE := 255


static func apply(baked_dir: String, target_size: Vector2i, manifest: Dictionary) -> Dictionary:
	var rules: Dictionary = manifest.get("gameplay_rules", {})
	if not bool(rules.get("edge_mountains_enabled", true)):
		return {"ok": true, "skipped": true}

	var files: Dictionary = manifest.get("files", {})
	var height_name := str(files.get("heightmap", ""))
	var blocker_name := str(files.get("movement_blocker", ""))
	var terrain_name := str(files.get("project_terrain_classes", ""))
	var scatter_name := str(files.get("no_scatter", ""))
	if height_name.is_empty() or blocker_name.is_empty() or terrain_name.is_empty():
		return {"ok": false, "errors": ["missing layer paths for edge processing"]}

	var height_path := baked_dir.path_join(height_name)
	var blocker_path := baked_dir.path_join(blocker_name)
	var terrain_path := baked_dir.path_join(terrain_name)
	var scatter_path := baked_dir.path_join(scatter_name)

	var height_img := Image.load_from_file(ProjectSettings.globalize_path(height_path))
	var blocker_img := Image.load_from_file(ProjectSettings.globalize_path(blocker_path))
	var terrain_img := Image.load_from_file(ProjectSettings.globalize_path(terrain_path))
	if height_img == null or blocker_img == null or terrain_img == null:
		return {"ok": false, "errors": ["failed to load baked layers for edge processing"]}
	height_img.convert(Image.FORMAT_RGBA8)
	blocker_img.convert(Image.FORMAT_RGBA8)
	terrain_img.convert(Image.FORMAT_RGBA8)

	var scatter_img: Image = null
	if not scatter_name.is_empty() and FileAccess.file_exists(ProjectSettings.globalize_path(scatter_path)):
		scatter_img = Image.load_from_file(ProjectSettings.globalize_path(scatter_path))
		if scatter_img != null:
			scatter_img.convert(Image.FORMAT_RGBA8)

	var cliff_color := Color.from_string(CLIFF_HEX, Color.PURPLE)
	var uplifted_cells := 0
	var blocked_cells := 0

	for y in range(target_size.y):
		for x in range(target_size.x):
			var edge_t := _edge_factor(x, y, target_size.x, target_size.y)
			if edge_t <= 0.0:
				continue
			var uplift := pow(edge_t, 1.55) * Constants.MAPGEN_EDGE_UPLIFT
			var pixel := height_img.get_pixel(x, y)
			var lifted := clampf(pixel.r + uplift, 0.0, 1.0)
			height_img.set_pixel(x, y, Color(lifted, lifted, lifted, pixel.a))
			uplifted_cells += 1

			var dist := _dist_to_rect_edge(Vector2i(x, y), target_size.x, target_size.y)
			if dist <= float(BORDER_UPLIFT_DEPTH):
				blocker_img.set_pixel(x, y, Color8(BLOCKER_VALUE, BLOCKER_VALUE, BLOCKER_VALUE, 255))
				terrain_img.set_pixel(x, y, cliff_color)
				blocked_cells += 1
			if scatter_img != null and dist <= float(BORDER_SCATTER_DEPTH):
				scatter_img.set_pixel(x, y, Color8(NO_SCATTER_VALUE, NO_SCATTER_VALUE, NO_SCATTER_VALUE, 255))

	var save_errors: PackedStringArray = []
	save_errors.append_array(_save_png(height_img, height_path))
	save_errors.append_array(_save_png(blocker_img, blocker_path))
	save_errors.append_array(_save_png(terrain_img, terrain_path))
	if scatter_img != null:
		save_errors.append_array(_save_png(scatter_img, scatter_path))

	if not save_errors.is_empty():
		return {"ok": false, "errors": save_errors}
	return {
		"ok": true,
		"uplifted_cells": uplifted_cells,
		"blocked_cells": blocked_cells,
		"border_uplift_depth": BORDER_UPLIFT_DEPTH,
	}


static func _edge_factor(x: int, y: int, width: int, height: int) -> float:
	var nx := float(x) / float(maxi(width - 1, 1))
	var ny := float(y) / float(maxi(height - 1, 1))
	var edge_x := minf(nx, 1.0 - nx) * 2.0
	var edge_y := minf(ny, 1.0 - ny) * 2.0
	var edge_t := clampf(minf(edge_x, edge_y), 0.0, 1.0)
	if edge_t >= 1.0:
		return 0.0
	return 1.0 - edge_t


static func _dist_to_rect_edge(cell: Vector2i, map_w: int, map_h: int) -> float:
	var left := float(cell.x)
	var top := float(cell.y)
	var right := float(map_w - 1 - cell.x)
	var bottom := float(map_h - 1 - cell.y)
	return minf(minf(left, right), minf(top, bottom))


static func _save_png(image: Image, path: String) -> PackedStringArray:
	var err := image.save_png(ProjectSettings.globalize_path(path))
	if err != OK:
		return PackedStringArray(["save failed %s err=%s" % [path, error_string(err)]])
	return PackedStringArray()
