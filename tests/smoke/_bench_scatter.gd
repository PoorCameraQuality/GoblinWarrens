extends SceneTree

func _init() -> void:
	var config := MapConfig.default_for_demo()
	var plan := MapPlan.new()
	plan.width = config.width
	plan.height = config.height
	plan.warren_cell = Vector2i(config.width / 2, config.height / 2)
	var hd := HeightmapGenerator.generate(config, plan.warren_cell, null)
	plan.heights = hd.heights
	plan.height_point_width = hd.point_width
	plan.height_point_height = hd.point_height
	plan.tile_classes = TerrainClassifier.classify_grid(
		plan.heights,
		plan.height_point_width,
		plan.height_point_height,
		config,
		plan.warren_cell,
		null,
	)
	var rng := MapRng.new(99)
	PropScatterer.scatter(plan, config, rng)
	print(
		"[bench-scatter] placements=%d trees=%d dressing=%d"
		% [
			plan.prop_placements.size(),
			int(plan.scatter_stats.get("tree_count", 0)),
			int(plan.scatter_stats.get("dressing_count", 0)),
		]
	)
	quit(0)
