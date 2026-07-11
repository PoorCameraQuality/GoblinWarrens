extends RefCounted

## Debug snapshots for goblin workers and colony job targets (Phase 9).
## Loaded at runtime in headless smokes — no class_name.


static func snapshot_goblin(goblin: Goblin, movement: MovementAdapter = null) -> Dictionary:
	if goblin == null or not goblin.is_alive():
		return {}
	var extra: Dictionary = goblin.dev_observation_extra()
	var path_total: int = int(extra.get("path_total", 0))
	var path_index: int = int(extra.get("path_index", 0))
	var destination := Vector2i(-1, -1)
	if path_total > 0:
		destination = extra.get("path_destination", Vector2i(-1, -1))
	var travel_cost := -1
	if movement != null and destination.x >= 0:
		var probe: Array[Vector2i] = movement.find_path(goblin.grid_cell, destination)
		travel_cost = maxi(0, probe.size() - 1)
	return {
		"actor_id": goblin.actor_id,
		"display_name": goblin.display_name,
		"grid_cell": goblin.grid_cell,
		"job_kind": int(goblin.job_kind),
		"worker_phase": int(goblin.worker_phase),
		"hp": goblin.hp,
		"max_hp": goblin.max_hp,
		"hunger": goblin.hunger,
		"energy": goblin.energy,
		"starvation_level": goblin.starvation_level,
		"carried_kind": int(goblin.carried_kind),
		"carried_amount": goblin.carried_amount,
		"path_total": path_total,
		"path_index": path_index,
		"path_remaining": int(extra.get("path_remaining", 0)),
		"destination": destination,
		"travel_cost": travel_cost,
		"player_owned": bool(extra.get("player_owned", false)),
		"gather_chain": bool(extra.get("gather_chain", false)),
		"target_label": str(extra.get("target_label", "")),
		"idle_hint": str(extra.get("idle_hint", "")),
		"is_foblin": goblin.is_foblin(),
		"is_warrior": goblin.is_hobgoblin_warrior,
		"is_mage": goblin.is_hobgoblin_mage,
	}


static func format_goblin(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return "Goblin not found or dead."
	var lines: PackedStringArray = PackedStringArray()
	lines.append(
		"%s (%s) @ %s"
		% [
			str(snapshot.get("display_name", "?")),
			str(snapshot.get("actor_id", "?")),
			str(snapshot.get("grid_cell", Vector2i.ZERO)),
		]
	)
	lines.append(
		"job=%s phase=%s target=%s"
		% [
			_job_kind_name(int(snapshot.get("job_kind", Defs.JobKind.IDLE))),
			_worker_phase_name(int(snapshot.get("worker_phase", Defs.WorkerPhase.IDLE))),
			str(snapshot.get("target_label", "none")),
		]
	)
	lines.append(
		"path=%d/%d rem=%d dest=%s travel=%s"
		% [
			int(snapshot.get("path_index", 0)),
			int(snapshot.get("path_total", 0)),
			int(snapshot.get("path_remaining", 0)),
			str(snapshot.get("destination", Vector2i(-1, -1))),
			_format_optional_int(snapshot.get("travel_cost", -1)),
		]
	)
	lines.append(
		"carry=%s x%d hp=%d/%d hunger=%.1f energy=%.1f starvation=%.1f"
		% [
			_resource_kind_name(int(snapshot.get("carried_kind", Defs.ResourceKind.WOOD))),
			int(snapshot.get("carried_amount", 0)),
			int(snapshot.get("hp", 0)),
			int(snapshot.get("max_hp", 0)),
			float(snapshot.get("hunger", 0.0)),
			float(snapshot.get("energy", 0.0)),
			float(snapshot.get("starvation_level", 0.0)),
		]
	)
	var flags: PackedStringArray = PackedStringArray()
	if bool(snapshot.get("player_owned", false)):
		flags.append("player_owned")
	if bool(snapshot.get("gather_chain", false)):
		flags.append("gather_chain")
	if bool(snapshot.get("is_foblin", false)):
		flags.append("foblin")
	if bool(snapshot.get("is_warrior", false)):
		flags.append("warrior")
	if bool(snapshot.get("is_mage", false)):
		flags.append("mage")
	if not flags.is_empty():
		lines.append("flags=%s" % ", ".join(flags))
	var idle_hint := str(snapshot.get("idle_hint", ""))
	if not idle_hint.is_empty():
		lines.append("idle_hint=%s" % idle_hint)
	return "\n".join(lines)


static func find_goblin(goblins: Array, query: String) -> Goblin:
	if goblins.is_empty():
		return null
	if query.is_empty():
		return goblins[0] as Goblin
	if query.is_valid_int():
		var index := int(query)
		if index >= 0 and index < goblins.size():
			return goblins[index] as Goblin
	for goblin in goblins:
		if goblin == null:
			continue
		if str(goblin.actor_id) == query or str(goblin.display_name) == query:
			return goblin as Goblin
	return null


static func format_all_goblins(goblins: Array, movement: MovementAdapter = null) -> String:
	if goblins.is_empty():
		return "No living goblins."
	var chunks: PackedStringArray = PackedStringArray()
	for i in range(goblins.size()):
		var goblin := goblins[i] as Goblin
		if goblin == null or not goblin.is_alive():
			continue
		chunks.append("[%d] %s" % [i, format_goblin(snapshot_goblin(goblin, movement))])
	return "\n---\n".join(chunks)


static func scan_job_inventory(tree: SceneTree) -> Dictionary:
	var inv := {
		"gather_available": 0,
		"gather_reserved": 0,
		"build_available": 0,
		"build_reserved": 0,
		"forage_available": 0,
		"forage_reserved": 0,
		"shrine_available": 0,
		"shrine_reserved": 0,
	}
	if tree == null:
		return inv
	for node in tree.get_nodes_in_group(Defs.GROUP_RESOURCE_NODE):
		if not node is ResourceNode:
			continue
		var resource := node as ResourceNode
		if not resource.is_available():
			continue
		if resource.reserved_by.is_empty():
			inv["gather_available"] = int(inv["gather_available"]) + 1
		else:
			inv["gather_reserved"] = int(inv["gather_reserved"]) + 1
	for node in tree.get_nodes_in_group(Defs.GROUP_CONSTRUCTION):
		if not node is ConstructionSite:
			continue
		var site := node as ConstructionSite
		if site.is_complete() or not site.resources_paid:
			continue
		if site.reserved_by.is_empty():
			inv["build_available"] = int(inv["build_available"]) + 1
		else:
			inv["build_reserved"] = int(inv["build_reserved"]) + 1
	for node in tree.get_nodes_in_group(Defs.GROUP_FORAGER_POST):
		if not node is ForagerPost:
			continue
		var post := node as ForagerPost
		if post.reserved_by.is_empty():
			inv["forage_available"] = int(inv["forage_available"]) + 1
		else:
			inv["forage_reserved"] = int(inv["forage_reserved"]) + 1
	for node in tree.get_nodes_in_group(Defs.GROUP_SHRINE):
		if not node is ShrineBuilding:
			continue
		var shrine := node as ShrineBuilding
		if shrine.reserved_by.is_empty():
			inv["shrine_available"] = int(inv["shrine_available"]) + 1
		else:
			inv["shrine_reserved"] = int(inv["shrine_reserved"]) + 1
	return inv


static func summarize_workers(goblins: Array) -> Dictionary:
	var summary := {
		"total": 0,
		"idle": 0,
		"moving": 0,
		"working": 0,
		"carrying": 0,
		"player_owned": 0,
		"by_job": {},
	}
	for goblin in goblins:
		if goblin == null or not goblin.is_alive():
			continue
		summary["total"] = int(summary["total"]) + 1
		if goblin.carried_amount > 0:
			summary["carrying"] = int(summary["carrying"]) + 1
		var extra: Dictionary = goblin.dev_observation_extra()
		if bool(extra.get("player_owned", false)):
			summary["player_owned"] = int(summary["player_owned"]) + 1
		match goblin.worker_phase:
			Defs.WorkerPhase.IDLE:
				summary["idle"] = int(summary["idle"]) + 1
			Defs.WorkerPhase.MOVE:
				summary["moving"] = int(summary["moving"]) + 1
			Defs.WorkerPhase.WORK:
				summary["working"] = int(summary["working"]) + 1
		var job_name := _job_kind_name(int(goblin.job_kind))
		var by_job: Dictionary = summary["by_job"]
		by_job[job_name] = int(by_job.get(job_name, 0)) + 1
		summary["by_job"] = by_job
	return summary


static func format_job_report(colony: GoblinWarrenColony) -> String:
	if colony == null:
		return "Colony unavailable."
	var tree := colony.get_tree()
	var goblins: Array = colony.dev_collect_goblins()
	var inv := scan_job_inventory(tree)
	var workers := summarize_workers(goblins)
	var lines: PackedStringArray = PackedStringArray()
	lines.append(
		"workers total=%d idle=%d moving=%d working=%d carrying=%d player_owned=%d"
		% [
			int(workers.get("total", 0)),
			int(workers.get("idle", 0)),
			int(workers.get("moving", 0)),
			int(workers.get("working", 0)),
			int(workers.get("carrying", 0)),
			int(workers.get("player_owned", 0)),
		]
	)
	var by_job: Dictionary = workers.get("by_job", {})
	if not by_job.is_empty():
		var job_parts: PackedStringArray = PackedStringArray()
		for job_name in by_job.keys():
			job_parts.append("%s=%d" % [job_name, int(by_job[job_name])])
		lines.append("jobs_by_kind: %s" % ", ".join(job_parts))
	lines.append(
		"targets gather=%d/%d build=%d/%d forage=%d/%d shrine=%d/%d (available/reserved)"
		% [
			int(inv.get("gather_available", 0)),
			int(inv.get("gather_reserved", 0)),
			int(inv.get("build_available", 0)),
			int(inv.get("build_reserved", 0)),
			int(inv.get("forage_available", 0)),
			int(inv.get("forage_reserved", 0)),
			int(inv.get("shrine_available", 0)),
			int(inv.get("shrine_reserved", 0)),
		]
	)
	var idle_without_job := 0
	for goblin in goblins:
		if goblin == null or not goblin.is_alive():
			continue
		if goblin.job_kind == Defs.JobKind.IDLE and goblin.carried_amount <= 0:
			idle_without_job += 1
	lines.append("idle_without_carry=%d" % idle_without_job)
	return "\n".join(lines)


static func format_mock_snapshot() -> String:
	var snap := {
		"display_name": "MockGob",
		"actor_id": "mock_01",
		"grid_cell": Vector2i(12, 34),
		"job_kind": Defs.JobKind.GATHER,
		"worker_phase": Defs.WorkerPhase.MOVE,
		"hp": 40,
		"max_hp": 40,
		"hunger": 18.5,
		"energy": 92.0,
		"starvation_level": 0.0,
		"carried_kind": Defs.ResourceKind.WOOD,
		"carried_amount": 0,
		"path_total": 8,
		"path_index": 2,
		"path_remaining": 6,
		"destination": Vector2i(20, 40),
		"travel_cost": 6,
		"player_owned": false,
		"gather_chain": false,
		"target_label": "tree@20,40",
		"idle_hint": "",
		"is_foblin": false,
		"is_warrior": false,
		"is_mage": false,
	}
	return format_goblin(snap)


static func _job_kind_name(kind: int) -> String:
	match kind:
		Defs.JobKind.IDLE:
			return "IDLE"
		Defs.JobKind.MOVE:
			return "MOVE"
		Defs.JobKind.GATHER:
			return "GATHER"
		Defs.JobKind.DELIVER:
			return "DELIVER"
		Defs.JobKind.BUILD:
			return "BUILD"
		Defs.JobKind.FORAGE:
			return "FORAGE"
		Defs.JobKind.PRAY:
			return "PRAY"
		Defs.JobKind.GUARD:
			return "GUARD"
		Defs.JobKind.FIGHT:
			return "FIGHT"
		_:
			return "UNKNOWN(%d)" % kind


static func _worker_phase_name(phase: int) -> String:
	match phase:
		Defs.WorkerPhase.IDLE:
			return "IDLE"
		Defs.WorkerPhase.MOVE:
			return "MOVE"
		Defs.WorkerPhase.WORK:
			return "WORK"
		_:
			return "UNKNOWN(%d)" % phase


static func _resource_kind_name(kind: int) -> String:
	match kind:
		Defs.ResourceKind.GOLD:
			return "GOLD"
		Defs.ResourceKind.WOOD:
			return "WOOD"
		Defs.ResourceKind.STONE:
			return "STONE"
		Defs.ResourceKind.FOOD:
			return "FOOD"
		Defs.ResourceKind.MAGIC:
			return "MAGIC"
		_:
			return "UNKNOWN(%d)" % kind


static func _format_optional_int(value: Variant) -> String:
	var number := int(value)
	if number < 0:
		return "n/a"
	return str(number)
