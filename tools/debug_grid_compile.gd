extends SceneTree

const _Compiler := preload("res://scripts/world/map/grid_compiler.gd")

func _init() -> void:
	print("[debug] compile start")
	var grid = _Compiler.compile_map("res://data/maps/three_lane_swamp_valley")
	if grid == null:
		print("[debug] grid null")
	else:
		print("[debug] walkable=%d" % grid.count_walkable_cells())
	quit(0)
