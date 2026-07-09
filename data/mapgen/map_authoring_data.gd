class_name MapAuthoringData
extends Resource

## Lightweight authored map masks for prop/tree scatter — not scene nodes.
## See `data/mapgen/demo_map_authoring.tres` for the shipped demo layout.

const DEMO_RESOURCE_PATH := "res://data/mapgen/demo_map_authoring.tres"

@export var forest_stamps: Array[Dictionary] = []
@export var clearing_stamps: Array[Dictionary] = []
@export var resource_stamps: Array[Dictionary] = []
@export var road_stamps: Array[Dictionary] = []
@export var edge_forest_enabled: bool = true

@export var tree_density_multiplier: float = 1.35
@export var bush_density_multiplier: float = 1.2
@export var mushroom_density_multiplier: float = 1.15
@export var rock_density_multiplier: float = 1.0
@export var grass_density_multiplier: float = 1.25


static func load_demo_or_build(map_width: int, map_height: int, warren_cell: Vector2i) -> MapAuthoringData:
	if ResourceLoader.exists(DEMO_RESOURCE_PATH):
		var loaded := load(DEMO_RESOURCE_PATH) as MapAuthoringData
		if loaded != null:
			return loaded
	return build_demo_layout(map_width, map_height, warren_cell)


static func build_demo_layout(map_width: int, map_height: int, warren_cell: Vector2i) -> MapAuthoringData:
	var data := MapAuthoringData.new()
	var cx := warren_cell.x + 1
	var cy := warren_cell.y + 1
	var edge_inset := maxi(8, mini(map_width, map_height) / 28)

	data.clearing_stamps = [
		_stamp(Vector2i(cx, cy), maxi(14, map_width / 14), 1.0, 2.0, "warren_clearing"),
		_stamp(Vector2i(cx, cy), maxi(22, map_width / 10), 0.55, 2.5, "camp_soft_edge"),
	]

	data.forest_stamps = [
		_stamp(Vector2i(cx, edge_inset + 18), maxi(40, map_width / 7), 0.95, 2.0, "north_band"),
		_stamp(Vector2i(cx, map_height - edge_inset - 18), maxi(40, map_width / 7), 0.95, 2.0, "south_band"),
		_stamp(Vector2i(edge_inset + 18, cy), maxi(40, map_width / 7), 0.95, 2.0, "west_band"),
		_stamp(Vector2i(map_width - edge_inset - 18, cy), maxi(40, map_width / 7), 0.95, 2.0, "east_band"),
		_stamp(Vector2i(cx - 38, cy - 28), 22, 0.78, 1.6, "cluster_nw_near"),
		_stamp(Vector2i(cx + 42, cy - 32), 24, 0.82, 1.6, "cluster_ne_near"),
		_stamp(Vector2i(cx - 36, cy + 34), 22, 0.76, 1.6, "cluster_sw_near"),
		_stamp(Vector2i(cx + 40, cy + 30), 24, 0.8, 1.6, "cluster_se_near"),
		_stamp(Vector2i(cx - 22, cy + 8), 16, 0.42, 1.4, "sparse_near_camp"),
		_stamp(Vector2i(cx + 18, cy - 14), 14, 0.38, 1.4, "sparse_near_camp"),
	]

	data.resource_stamps = [
		_stamp(Vector2i(cx - 22, cy + 18), 12, 0.95, 1.5, "food"),
		_stamp(Vector2i(cx + 26, cy - 16), 11, 0.92, 1.5, "food"),
		_stamp(Vector2i(cx + 34, cy + 22), 10, 0.88, 1.4, "food"),
		_stamp(Vector2i(cx - 30, cy - 24), 12, 0.9, 1.6, "stone"),
		_stamp(Vector2i(cx + 38, cy + 12), 11, 0.88, 1.5, "stone"),
		_stamp(Vector2i(cx + 44, cy - 28), 10, 0.85, 1.4, "gold"),
	]

	data.road_stamps = [
		_stamp(Vector2i(cx + 28, cy), 8, 1.0, 1.1, "approach_east"),
		_stamp(Vector2i(cx - 28, cy), 8, 1.0, 1.1, "approach_west"),
		_stamp(Vector2i(cx, cy + 28), 8, 1.0, 1.1, "approach_south"),
		_stamp(Vector2i(cx, cy - 28), 8, 1.0, 1.1, "approach_north"),
		_stamp(Vector2i(cx + 18, cy), 6, 0.85, 1.0, "valley_east"),
		_stamp(Vector2i(cx - 18, cy), 6, 0.85, 1.0, "valley_west"),
		_stamp(Vector2i(cx, cy + 18), 6, 0.85, 1.0, "valley_south"),
		_stamp(Vector2i(cx, cy - 18), 6, 0.85, 1.0, "valley_north"),
		_stamp(Vector2i(cx, cy), maxi(18, map_width / 18), 0.55, 2.0, "camp_lane"),
	]

	data.edge_forest_enabled = true
	data.tree_density_multiplier = 1.35
	data.bush_density_multiplier = 1.2
	data.mushroom_density_multiplier = 1.15
	data.rock_density_multiplier = 1.0
	data.grass_density_multiplier = 1.25
	return data


static func _stamp(
	center: Vector2i,
	radius: int,
	strength: float,
	falloff: float = 1.5,
	tag: String = "",
) -> Dictionary:
	return {
		"center": center,
		"radius": radius,
		"strength": strength,
		"falloff": falloff,
		"tag": tag,
	}


func sample_stamp_mask(cell: Vector2i, stamps: Array[Dictionary]) -> float:
	var peak := 0.0
	for stamp in stamps:
		var center: Vector2i = stamp.get("center", Vector2i.ZERO)
		var radius: int = int(stamp.get("radius", 0))
		if radius <= 0:
			continue
		var strength: float = float(stamp.get("strength", 0.0))
		var falloff: float = maxf(float(stamp.get("falloff", 1.5)), 0.01)
		var dist := Vector2(cell).distance_to(Vector2(center))
		if dist > float(radius):
			continue
		var edge := 1.0 - dist / float(radius)
		var shaped := pow(maxf(edge, 0.0), falloff) * strength
		peak = maxf(peak, shaped)
	return clampf(peak, 0.0, 1.0)


func sample_clearing_strength(cell: Vector2i) -> float:
	return sample_stamp_mask(cell, clearing_stamps)


func is_in_road_or_approach_lane(cell: Vector2i) -> bool:
	return sample_stamp_mask(cell, road_stamps) >= 0.35


func sample_forest_density(cell: Vector2i, terrain_class: Defs.TerrainClass) -> float:
	## Legacy entry — prefer `sample_forest_density_for_plan` when MapPlan is available.
	var clearing := sample_clearing_strength(cell)
	if clearing >= 0.65:
		return 0.0
	if is_in_road_or_approach_lane(cell):
		return _terrain_forest_base(terrain_class) * 0.12 * tree_density_multiplier
	var base := _terrain_forest_base(terrain_class)
	var stamp_boost := sample_stamp_mask(cell, forest_stamps)
	var density := (base + stamp_boost * 0.9) * tree_density_multiplier
	density *= 1.0 - clearing * 0.95
	return clampf(density, 0.0, 1.35)


func sample_forest_density_for_plan(cell: Vector2i, plan: MapPlan, terrain_class: Defs.TerrainClass) -> float:
	var clearing := sample_clearing_strength(cell)
	if clearing >= 0.65:
		return 0.0
	if is_in_road_or_approach_lane(cell):
		return _terrain_forest_base(terrain_class) * 0.12 * tree_density_multiplier

	var base := _terrain_forest_base(terrain_class)
	var stamp_boost := sample_stamp_mask(cell, forest_stamps)
	var edge_boost := edge_forest_boost_for_map(cell, plan.width, plan.height)
	var density := (base + stamp_boost * 0.9 + edge_boost * 0.75) * tree_density_multiplier
	density *= 1.0 - clearing * 0.95
	return clampf(density, 0.0, 1.35)


func sample_resource_bias(cell: Vector2i, kind: Defs.ResourceKind) -> float:
	var bias := 1.0
	for stamp in resource_stamps:
		var tag := str(stamp.get("tag", "")).to_lower()
		var mask := sample_stamp_mask(cell, [stamp])
		if mask <= 0.01:
			continue
		match kind:
			Defs.ResourceKind.FOOD:
				if tag == "food" or tag == "mushroom":
					bias += mask * 4.0
			Defs.ResourceKind.STONE:
				if tag == "stone" or tag == "rock":
					bias += mask * 4.0
			Defs.ResourceKind.GOLD:
				if tag == "gold":
					bias += mask * 5.0
			_:
				pass
	return bias


func stamp_counts_summary() -> Dictionary:
	return {
		"forest_stamp_count": forest_stamps.size(),
		"clearing_stamp_count": clearing_stamps.size(),
		"resource_stamp_count": resource_stamps.size(),
		"road_stamp_count": road_stamps.size(),
	}


func edge_forest_boost_for_map(cell: Vector2i, map_width: int, map_height: int) -> float:
	if not edge_forest_enabled:
		return 0.0
	var dist_edge := _dist_to_rect_edge(cell, map_width, map_height)
	var band := 14.0
	if dist_edge > band:
		return 0.0
	return (1.0 - dist_edge / band) * 0.95


func _dist_to_rect_edge(cell: Vector2i, map_w: int, map_h: int) -> float:
	var left := float(cell.x)
	var top := float(cell.y)
	var right := float(map_w - 1 - cell.x)
	var bottom := float(map_h - 1 - cell.y)
	return minf(minf(left, right), minf(top, bottom))


func _terrain_forest_base(terrain_class: Defs.TerrainClass) -> float:
	match terrain_class:
		Defs.TerrainClass.FOREST_FLOOR:
			return 0.72
		Defs.TerrainClass.MOSS:
			return 0.28
		Defs.TerrainClass.MUD_MOSSY:
			return 0.22
		Defs.TerrainClass.ROCKY_SLOPE:
			return 0.08
		_:
			return 0.0
