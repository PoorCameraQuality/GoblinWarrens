class_name GoblinMapDefinition
extends Resource

## Typed authored map definition loaded from manifest + import report.
## See docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md §6.

@export var map_id: String = ""
@export var display_name: String = ""
@export var map_version: int = 1
@export var map_seed: int = 0
@export var map_root: String = ""
@export var grid_width: int = Constants.GRID_WIDTH
@export var grid_height: int = Constants.GRID_HEIGHT
@export var terrain_heightmap_path: String = ""
@export var terrain3d_data_dir: String = ""
@export var baked_dir: String = ""
@export var source_dir: String = ""
@export var layer_paths: Dictionary = {}
@export var biomes: Array = []
@export var fixed_placements: Array = []
@export var resource_rules: Array = []
@export var validation_profile: Resource
@export var seed_foliage: int = 0
@export var seed_harvestable: int = 0
@export var seed_resource: int = 0
@export var seed_ambient: int = 0
@export var seed_enemy: int = 0
@export var seed_clutter: int = 0


func get_layer_path(layer_key: String) -> String:
	return str(layer_paths.get(layer_key, ""))


func get_source_layer_path(layer_key: String, manifest_files: Dictionary) -> String:
	var file_name := str(manifest_files.get(layer_key, ""))
	if file_name.is_empty() or source_dir.is_empty():
		return ""
	return source_dir.path_join(file_name)


func grid_size() -> Vector2i:
	return Vector2i(grid_width, grid_height)
