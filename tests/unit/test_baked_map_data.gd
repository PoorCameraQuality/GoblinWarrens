extends GutTest

## Unit coverage for BakedMapData compile bridge.

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const _Factory := preload("res://scripts/world/map/map_definition_factory.gd")


func test_baked_map_data_compiles_grid() -> void:
	var baked: BakedMapData = _Factory.create_baked_map_data(MAP_ROOT)
	assert_not_null(baked)
	assert_true(baked.is_ready())
	var grid: CompiledGridMap = baked.compile_grid()
	assert_not_null(grid)
	assert_eq(grid.width, Constants.GRID_WIDTH)
	assert_true(grid.count_walkable_cells() > 90000)
	assert_true(grid.count_buildable_cells() > 1000)


func test_baked_map_data_without_definition_is_not_ready() -> void:
	var baked := BakedMapData.new()
	assert_false(baked.is_ready())
	assert_null(baked.compile_grid())
