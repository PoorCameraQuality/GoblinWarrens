extends SceneTree

func _init() -> void:
	var config := MapConfig.default_for_demo()
	var plan := MapGenerator.build(config)
	var result := MapValidator.validate(plan, config)
	print(MapValidator.format_report(result))
	for failure in result.get("failures", []):
		print("FAIL: ", failure)
	print("stats=", plan.scatter_stats)
	quit(0 if result.pass else 1)
