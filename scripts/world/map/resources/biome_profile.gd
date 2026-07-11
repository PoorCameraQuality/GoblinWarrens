class_name BiomeProfile
extends Resource

## Authored biome palette entry. Initial four biomes expand in later phases.

@export var biome_id: int = 0
@export var display_name: String = ""
@export var palette_color: Color = Color.BLACK
@export var min_height_m: float = 0.0
@export var max_height_m: float = 100.0
@export var tree_density: float = 0.5
