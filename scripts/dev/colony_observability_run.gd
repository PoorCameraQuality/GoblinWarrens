extends RefCounted

## Phase 9 colony observability validation (single static entry — loaded at runtime).


static func run() -> Dictionary:
	var Observability = load("res://scripts/debug/colony_observability.gd")
	if Observability == null:
		return _fail("observability_load_failed")

	var mock_text: String = Observability.format_mock_snapshot()
	if mock_text.is_empty():
		return _fail("mock_snapshot_empty")
	if not mock_text.contains("GATHER") or not mock_text.contains("mock_01"):
		return _fail("mock_snapshot_missing_fields")

	var empty_inv: Dictionary = Observability.scan_job_inventory(null)
	if int(empty_inv.get("gather_available", -1)) != 0:
		return _fail("empty_inventory_scan")

	var worker_summary: Dictionary = Observability.summarize_workers([])
	if int(worker_summary.get("total", -1)) != 0:
		return _fail("empty_worker_summary")

	var log_line := "ok mock_lines=%d inventory_keys=%d" % [
		mock_text.count("\n") + 1,
		empty_inv.size(),
	]
	return {"ok": true, "log_line": log_line}


static func _fail(message: String) -> Dictionary:
	return {"ok": false, "log_line": "FAIL %s" % message}
