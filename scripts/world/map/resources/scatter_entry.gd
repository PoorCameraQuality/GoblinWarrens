class_name ScatterEntry
extends Resource

## One decorative scatter species entry for authored map bakes.

@export var species_id: StringName = &""
@export var density_per_1000m2: float = 0.0
@export var min_spacing_m: float = 1.0
@export var allowed_biome_ids: PackedInt32Array = PackedInt32Array()
