extends SceneTree

## Writes `data/mapgen/demo_map_authoring.tres` from the demo layout builder.
## godot --headless --path . --script tools/write_demo_map_authoring.gd

const _MapConfig := preload("res://data/mapgen/map_config.gd")
const _MapAuthoringData := preload("res://data/mapgen/map_authoring_data.gd")

const OUTPUT_PATH := "res://data/mapgen/demo_map_authoring.tres"


func _init() -> void:
	var config := _MapConfig.new()
	config.width = Constants.GRID_WIDTH
	config.height = Constants.GRID_HEIGHT
	var warren_cell := Vector2i(
		config.width / 2 - config.warren_footprint.x / 2,
		config.height / 2 - config.warren_footprint.y / 2,
	)
	var data := _MapAuthoringData.build_demo_layout(config.width, config.height, warren_cell)
	var err := ResourceSaver.save(data, OUTPUT_PATH)
	if err != OK:
		push_error("[write-demo-authoring] save failed err=%s" % str(err))
		quit(1)
		return
	print("[write-demo-authoring] ok path=%s forest=%d clearing=%d" % [
		OUTPUT_PATH,
		data.forest_stamps.size(),
		data.clearing_stamps.size(),
	])
	quit(0)
