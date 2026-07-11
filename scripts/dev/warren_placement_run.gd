extends RefCounted

## Phase 7 Warren placement validation (single static entry — loaded at runtime).

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"


static func run() -> Dictionary:
	var Controller = load("res://scripts/world/warren/warren_placement_controller.gd")
	if Controller == null:
		return _fail("controller_load_failed")

	var context: Dictionary = Controller.load_context(MAP_ROOT)
	if context.is_empty():
		return _fail("context_load_failed")

	var first: Array = Controller.find_candidates(context)
	var second: Array = Controller.find_candidates(context)
	if first.is_empty():
		return _fail("no_valid_candidates")

	if first.size() != second.size():
		return _fail("determinism_count %d/%d" % [first.size(), second.size()])

	var top: Dictionary = first[0]
	if int(top.get("score", 0)) < 40:
		return _fail("top_score_too_low=%d" % int(top.get("score", 0)))

	if top.get("origin", Vector2i.ZERO).y < int(context["grid"].height) * 0.45:
		return _fail("top_candidate_not_in_south_half")

	var log_line := (
		"ok candidates=%d top=%s score=%d label=%s"
		% [
			first.size(),
			str(top.get("origin", Vector2i.ZERO)),
			int(top.get("score", 0)),
			str(top.get("label_name", "")),
		]
	)
	return {"ok": true, "log_line": log_line, "candidates": first, "context": context}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
