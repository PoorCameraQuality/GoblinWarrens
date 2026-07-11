class_name MapConfig
extends Resource

## Tunable parameters for procedural map generation.

const DEMO_AUTHORING_PATH := "res://data/mapgen/demo_map_authoring.tres"

@export var width: int = Constants.GRID_WIDTH
@export var height: int = Constants.GRID_HEIGHT
@export var seed: int = Constants.MAPGEN_DEMO_SEED
@export var height_scale: float = Constants.MAPGEN_HEIGHT_SCALE
@export var camp_flat_radius: int = Constants.MAPGEN_CAMP_FLAT_RADIUS
@export var camp_blend_radius: int = Constants.MAPGEN_CAMP_BLEND_RADIUS
@export var warren_footprint: Vector2i = Vector2i(4, 4)
@export var authoring_data: MapAuthoringData = null


static func default_for_demo() -> MapConfig:
	var config := MapConfig.new()
	config.seed = Constants.MAPGEN_DEMO_SEED
	config.width = Constants.GRID_WIDTH
	config.height = Constants.GRID_HEIGHT
	var min_dim: int = mini(config.width, config.height)
	config.camp_flat_radius = maxi(Constants.MAPGEN_CAMP_FLAT_RADIUS, min_dim / 14)
	config.camp_blend_radius = maxi(Constants.MAPGEN_CAMP_BLEND_RADIUS, min_dim / 8)
	## Authoring is rebuilt in MapGenerator from warren_cell so clearing/roads
	## stay centered; optional DEMO_AUTHORING_PATH override remains available.
	config.authoring_data = null
	return config
