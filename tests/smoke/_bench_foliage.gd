extends SceneTree

const _MapConfig := preload("res://data/mapgen/map_config.gd")
const _MapGenerator := preload("res://scripts/world/mapgen/map_generator.gd")


func _init() -> void:
	var t0 := Time.get_ticks_msec()
	var config := _MapConfig.default_for_demo()
	var plan := _MapGenerator.build(config)
	var t1 := Time.get_ticks_msec()
	print("[bench-foliage] build_ms=%d chunks=%d inst=%d ambient=%d" % [
		t1 - t0,
		0 if plan.foliage_plan == null else plan.foliage_plan.chunks.size(),
		0 if plan.foliage_plan == null else int(plan.foliage_plan.stats.get("instance_estimate", 0)),
		0 if plan.foliage_plan == null else int(plan.foliage_plan.stats.get("ambient_zones", 0)),
	])
	quit(0)
