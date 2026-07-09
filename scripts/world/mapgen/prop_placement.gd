extends RefCounted

## One scattered prop or resource spawn from map generation.

var scene_path: String = ""
var grid_cell: Vector2i = Vector2i.ZERO
var world_pos: Vector3 = Vector3.ZERO
var rotation_y: float = 0.0
var scale: Vector3 = Vector3.ONE
var blocks_movement: bool = false
var resource_kind: int = -1 ## Defs.ResourceKind or -1 for scenery only
var resource_amount: int = 0
var terrain_class: int = 0 ## Defs.TerrainClass at scatter cell
