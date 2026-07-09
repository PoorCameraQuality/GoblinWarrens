class_name MapPlan
extends RefCounted

## Output of MapGenerator.build(): terrain mesh + gameplay grid metadata.

var width: int = 0
var height: int = 0
var mesh: ArrayMesh = null
var heights: PackedFloat32Array = PackedFloat32Array()
var height_point_width: int = 0
var height_point_height: int = 0
var tile_classes: Array = [] ## rows of Defs.TerrainClass
var warren_cell: Vector2i = Vector2i.ZERO
var storehouse_cell: Vector2i = Vector2i.ZERO
var prop_placements: Array = [] ## Array[PropPlacement]
var scatter_stats: Dictionary = {} ## debug counts from PropScatterer.scatter
var blend_control: Texture2D = null
var blend_stats: Dictionary = {}
var height_min: float = 0.0
var height_max: float = 0.0
