extends GutTest

## Unit coverage for authored map definition resources.

const MAP_ROOT := "res://data/maps/three_lane_swamp_valley"
const _Factory := preload("res://scripts/world/map/map_definition_factory.gd")


func test_factory_loads_swamp_valley_definition() -> void:
	var def: GoblinMapDefinition = _Factory.load_from_map_root(MAP_ROOT)
	assert_not_null(def)
	assert_eq(def.map_id, "three_lane_swamp_valley_reference")
	assert_eq(def.display_name, "Three-Lane Swamp Valley")
	assert_eq(def.grid_width, Constants.GRID_WIDTH)
	assert_false(def.baked_dir.is_empty())
	assert_false(def.get_layer_path("heightmap").is_empty())
	assert_false(def.get_layer_path("biome_id").is_empty())


func test_definition_has_biome_palette_profiles() -> void:
	var def: GoblinMapDefinition = _Factory.load_from_map_root(MAP_ROOT)
	assert_true(def.biomes.size() >= 4)
	var has_wetland := false
	for biome: BiomeProfile in def.biomes:
		if biome.biome_id == 3:
			has_wetland = true
			break
	assert_true(has_wetland)


func test_validation_profile_from_manifest() -> void:
	var def: GoblinMapDefinition = _Factory.load_from_map_root(MAP_ROOT)
	assert_not_null(def.validation_profile)
	assert_almost_eq(def.validation_profile.swamp_speed_multiplier, 0.1, 0.001)
	assert_true(def.validation_profile.mountains_impassable)


func test_seed_channels_are_deterministic() -> void:
	var def_a: GoblinMapDefinition = _Factory.load_from_map_root(MAP_ROOT)
	var def_b: GoblinMapDefinition = _Factory.load_from_map_root(MAP_ROOT)
	assert_eq(def_a.seed_foliage, def_b.seed_foliage)
	assert_ne(def_a.seed_foliage, def_a.seed_enemy)
