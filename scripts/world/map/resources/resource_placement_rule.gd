class_name ResourcePlacementRule
extends Resource

## Bake-time rule for harvestable resource placement on authored maps.

@export var resource_kind: int = Defs.ResourceKind.WOOD
@export var affinity_id: int = 0
@export var min_distance_m: float = 2.0
@export var max_per_cluster: int = 5
