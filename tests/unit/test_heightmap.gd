extends GutTest

## Unit coverage for procedural heightmap determinism.


func test_heightmap_is_deterministic_for_seed() -> void:
	var config := MapConfig.default_for_demo()
	var warren_cell := Vector2i(9, 9)
	var first := HeightmapGenerator.generate(config, warren_cell)
	var second := HeightmapGenerator.generate(config, warren_cell)
	assert_eq(first.heights.size(), second.heights.size())
	for i in range(first.heights.size()):
		assert_almost_eq(first.heights[i], second.heights[i], 0.0001)


func test_heightmap_changes_when_seed_changes() -> void:
	var config_a := MapConfig.default_for_demo()
	var config_b := MapConfig.default_for_demo()
	config_b.seed += 99
	var warren_cell := Vector2i(9, 9)
	var first := HeightmapGenerator.generate(config_a, warren_cell)
	var second := HeightmapGenerator.generate(config_b, warren_cell)
	var differs := false
	for i in range(first.heights.size()):
		if absf(first.heights[i] - second.heights[i]) > 0.0001:
			differs = true
			break
	assert_true(differs)
