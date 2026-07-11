extends SceneTree

## Smoke test for semantic map import pipeline.
## godot --headless --path . --script tests/smoke/test_semantic_map_import.gd

const _Importer := preload("res://scripts/world/map/map_semantic_importer.gd")
const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


func _init() -> void:
	var manifest_path := MAP_ROOT.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		push_error("[semantic-map-smoke] missing manifest")
		quit(1)
		return

	var report: Dictionary = _Importer.import_map(MAP_ROOT)
	if not bool(report.get("ok", false)):
		push_error("[semantic-map-smoke] import failed: %s" % str(report.get("validation", {})))
		quit(1)
		return

	var baked_dir: String = str(report.get("baked_dir", ""))
	var height_path := baked_dir.path_join("01_heightmap.png")
	if not FileAccess.file_exists(height_path):
		push_error("[semantic-map-smoke] missing baked heightmap")
		quit(1)
		return

	var height_img := Image.load_from_file(height_path)
	if height_img == null:
		push_error("[semantic-map-smoke] failed to load baked heightmap")
		quit(1)
		return

	if height_img.get_width() != Constants.GRID_WIDTH or height_img.get_height() != Constants.GRID_HEIGHT:
		push_error(
			"[semantic-map-smoke] baked size mismatch got=%dx%d"
			% [height_img.get_width(), height_img.get_height()]
		)
		quit(1)
		return

	print("[semantic-map-smoke] ok map=%s size=%dx%d" % [
		str(report.get("map_id", "")),
		height_img.get_width(),
		height_img.get_height(),
	])
	quit(0)
