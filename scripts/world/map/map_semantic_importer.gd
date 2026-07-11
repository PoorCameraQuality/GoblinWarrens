class_name MapSemanticImporter
extends RefCounted

## Resamples authored semantic map PNG layers to the gameplay grid and validates them.
## See data/maps/three_lane_swamp_valley/manifest.json

const DEFAULT_TARGET_SIZE := Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)

const ROAD_BIOME_HEX := "#8B6914"
const WETLAND_BIOME_HEX := "#52B788"
const FULL_SPEED_COST := 255
const SWAMP_SPEED := 26 ## ~10% of 255


static func import_map(
	map_root: String,
	target_size: Vector2i = DEFAULT_TARGET_SIZE,
) -> Dictionary:
	var manifest_path := map_root.path_join("manifest.json")
	var manifest: Dictionary = _load_json(manifest_path)
	if manifest.is_empty():
		return _fail("missing or invalid manifest at %s" % manifest_path)

	var source_dir := map_root.path_join("source")
	var baked_dir := map_root.path_join("baked").path_join("%d" % target_size.x)
	DirAccess.make_dir_recursive_absolute(_abs(baked_dir))

	var files: Dictionary = manifest.get("files", {})
	var import_resample: Dictionary = manifest.get("import_resample", {})
	var baked_files: Dictionary = {}
	var layer_sizes: Dictionary = {}

	for layer_key: String in files.keys():
		var file_name: String = str(files[layer_key])
		var source_path := _abs(source_dir.path_join(file_name))
		var baked_path := baked_dir.path_join(file_name)
		var baked_abs := _abs(baked_path)
		if not FileAccess.file_exists(source_path):
			return _fail("missing source layer %s at %s" % [layer_key, source_path])

		var image := Image.load_from_file(source_path)
		if image == null or image.is_empty():
			return _fail("failed to load image %s" % source_path)

		layer_sizes[layer_key] = Vector2i(image.get_width(), image.get_height())
		var filter := _filter_for_layer(layer_key, import_resample)
		if image.get_width() != target_size.x or image.get_height() != target_size.y:
			image.resize(target_size.x, target_size.y, filter)

		var err := image.save_png(baked_abs)
		if err != OK:
			return _fail("failed to save baked layer %s err=%s" % [baked_abs, error_string(err)])
		baked_files[layer_key] = baked_path

	var edge_report: Dictionary = {}
	var EdgeProcessor = load("res://scripts/world/map/authored_edge_processor.gd")
	if EdgeProcessor != null:
		edge_report = EdgeProcessor.apply(baked_dir, target_size, manifest)
		if not bool(edge_report.get("ok", false)):
			return _fail(
				"edge processing failed: %s" % str(edge_report.get("errors", []))
			)

	var validation := validate_baked_layers(baked_dir, files, manifest, target_size)
	var report := {
		"ok": bool(validation.get("pass", false)),
		"map_id": str(manifest.get("map_id", "")),
		"display_name": str(manifest.get("display_name", "")),
		"source_dir": source_dir,
		"baked_dir": baked_dir,
		"target_size": target_size,
		"layer_sizes_native": layer_sizes,
		"baked_files": baked_files,
		"edge_processing": edge_report,
		"validation": validation,
	}
	_save_json(map_root.path_join("import_report.json"), report)
	return report


static func validate_baked_layers(
	baked_dir: String,
	files: Dictionary,
	manifest: Dictionary,
	target_size: Vector2i = DEFAULT_TARGET_SIZE,
) -> Dictionary:
	var biome_path := _abs(baked_dir.path_join(str(files.get("biome_id", ""))))
	var road_path := _abs(baked_dir.path_join(str(files.get("road_clearance", ""))))
	var cost_path := _abs(baked_dir.path_join(str(files.get("movement_cost", ""))))
	var scatter_path := _abs(baked_dir.path_join(str(files.get("no_scatter", ""))))

	var biome_img := Image.load_from_file(biome_path)
	var road_img := Image.load_from_file(road_path)
	var cost_img := Image.load_from_file(cost_path)
	var scatter_img := Image.load_from_file(scatter_path)
	if biome_img == null or road_img == null or cost_img == null or scatter_img == null:
		return {"pass": false, "errors": PackedStringArray(["missing core validation layers"])}

	biome_img.convert(Image.FORMAT_RGBA8)
	road_img.convert(Image.FORMAT_RGBA8)
	cost_img.convert(Image.FORMAT_RGBA8)
	scatter_img.convert(Image.FORMAT_RGBA8)
	var road_color := Color.from_string(ROAD_BIOME_HEX, Color.BLACK)
	var wetland_color := Color.from_string(WETLAND_BIOME_HEX, Color.BLACK)
	var swamp_overlap := 0
	var road_not_full_speed := 0
	var road_not_road_biome := 0
	var road_not_no_scatter := 0
	var width := biome_img.get_width()
	var height := biome_img.get_height()

	for y in range(height):
		for x in range(width):
			if not _is_road_cell(road_img, x, y):
				continue
			var biome_px := biome_img.get_pixel(x, y)
			if biome_px.is_equal_approx(wetland_color):
				swamp_overlap += 1
			if not biome_px.is_equal_approx(road_color):
				road_not_road_biome += 1
			var cost_v := int(cost_img.get_pixel(x, y).r8)
			if cost_v != FULL_SPEED_COST:
				road_not_full_speed += 1
			if scatter_img.get_pixel(x, y).r8 < 250:
				road_not_no_scatter += 1

	var errors := PackedStringArray()
	if swamp_overlap > 0:
		errors.append("swamp_overlaps_road_pixels=%d" % swamp_overlap)
	if road_not_full_speed > 0:
		errors.append("road_pixels_not_full_speed=%d" % road_not_full_speed)
	if road_not_road_biome > 0:
		errors.append("road_pixels_not_road_biome=%d" % road_not_road_biome)
	if road_not_no_scatter > 0:
		errors.append("road_pixels_not_no_scatter=%d" % road_not_no_scatter)

	var aligned := _all_layers_exist(baked_dir, files)
	if not aligned:
		errors.append("baked_layers_not_aligned")

	return {
		"pass": errors.is_empty(),
		"swamp_overlaps_road_pixels": swamp_overlap,
		"road_pixels_not_full_speed": road_not_full_speed,
		"road_pixels_not_road_biome": road_not_road_biome,
		"road_pixels_not_no_scatter": road_not_no_scatter,
		"all_layers_aligned": aligned,
		"errors": errors,
		"gameplay_rules": manifest.get("gameplay_rules", {}),
	}


static func _filter_for_layer(layer_key: String, import_resample: Dictionary) -> Image.Interpolation:
	if layer_key == "heightmap":
		var mode := str(import_resample.get("heightmap", "bilinear_or_bicubic"))
		if mode.contains("bicubic") or mode.contains("lanczos"):
			return Image.INTERPOLATE_LANCZOS
		return Image.INTERPOLATE_BILINEAR
	return Image.INTERPOLATE_NEAREST


static func _is_road_cell(road_img: Image, x: int, y: int) -> bool:
	return road_img.get_pixel(x, y).r8 >= 250


static func _all_layers_exist(baked_dir: String, files: Dictionary) -> bool:
	for layer_key: String in files.keys():
		var path := _abs(baked_dir.path_join(str(files[layer_key])))
		if not FileAccess.file_exists(path):
			return false
	return true


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path)


static func _load_json(path: String) -> Dictionary:
	var abs_path := _abs(path)
	if not FileAccess.file_exists(abs_path):
		return {}
	var text := FileAccess.get_file_as_string(abs_path)
	if text.is_empty():
		return {}
	var parsed: Variant = JSON.parse_string(text)
	return parsed if parsed is Dictionary else {}


static func _save_json(path: String, data: Variant) -> void:
	var file := FileAccess.open(_abs(path), FileAccess.WRITE)
	if file == null:
		push_error("[map_import] failed to write %s" % path)
		return
	file.store_string(JSON.stringify(data, "\t"))


static func _fail(message: String) -> Dictionary:
	push_error("[map_import] %s" % message)
	return {"ok": false, "error": message, "validation": {"pass": false, "errors": PackedStringArray([message])}}
