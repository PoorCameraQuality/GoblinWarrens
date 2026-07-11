extends SceneTree

const _Importer := preload("res://scripts/world/map/map_semantic_importer.gd")

func _init() -> void:
	print("[debug-import] calling import_map")
	var report: Dictionary = _Importer.import_map("res://data/maps/three_lane_swamp_valley")
	print("[debug-import] ok=%s" % report.get("ok"))
	if report.has("validation"):
		print("[debug-import] validation=%s" % str(report.get("validation")))
	if report.has("error"):
		print("[debug-import] error=%s" % report.get("error"))
	quit(0 if bool(report.get("ok", false)) else 1)
