extends SceneTree

## Import and validate three_lane_swamp_valley semantic map layers.
## godot --headless --path . --script tools/import_semantic_map.gd
const _Importer := preload("res://scripts/world/map/map_semantic_importer.gd")
const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


func _init() -> void:
	var report: Dictionary = _Importer.import_map(MAP_ROOT)
	if not bool(report.get("ok", false)):
		var errors: Variant = report.get("validation", {}).get("errors", PackedStringArray())
		push_error("[semantic-map-import] failed: %s" % str(errors))
		quit(1)
		return

	print(
		"[semantic-map-import] ok map=%s baked=%s swamp_overlap=%d"
		% [
			str(report.get("map_id", "")),
			str(report.get("baked_dir", "")),
			int(report.get("validation", {}).get("swamp_overlaps_road_pixels", -1)),
		]
	)
	quit(0)
