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

## Runtime caches filled by bake_masks() — avoid per-cell stamp scans on 350 maps.
var _clearing_mask: PackedFloat32Array = PackedFloat32Array()
var _road_mask: PackedFloat32Array = PackedFloat32Array()
var _mask_width: int = 0
var _mask_height: int = 0


func bake_masks(map_width: int, map_height: int) -> void:
	_mask_width = map_width
	_mask_height = map_height
	var count := map_width * map_height
	_clearing_mask = PackedFloat32Array()
	_clearing_mask.resize(count)
	_road_mask = PackedFloat32Array()
	_road_mask.resize(count)
	_splat_stamps_into_mask(_clearing_mask, clearing_stamps, map_width, map_height, true)
	_splat_stamps_into_mask(_road_mask, road_stamps, map_width, map_height, false)


func _splat_stamps_into_mask(
	mask: PackedFloat32Array,
	stamps: Array[Dictionary],
	map_width: int,
	map_height: int,
	apply_wobble: bool,
) -> void:
	for stamp in stamps:
		var radius: int = int(stamp.get("radius", 0))
		if radius <= 0:
			continue
		var strength: float = float(stamp.get("strength", 0.0))
		var falloff: float = maxf(float(stamp.get("falloff", 1.5)), 0.01)
		var is_path := bool(stamp.get("is_path", false))
		if is_path:
			_splat_path_stamp(mask, stamp, radius, strength, falloff, map_width, map_height)
			continue
		var center: Vector2i = stamp.get("center", Vector2i.ZERO)
		var min_x := maxi(0, center.x - radius)
		var max_x := mini(map_width - 1, center.x + radius)
		var min_y := maxi(0, center.y - radius)
		var max_y := mini(map_height - 1, center.y + radius)
		var r_f := float(radius)
		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				var dist := Vector2(x - center.x, y - center.y).length()
				if dist > r_f:
					continue
				var edge := 1.0 - dist / r_f
				var shaped := pow(maxf(edge, 0.0), falloff) * strength
				if apply_wobble:
					shaped = clampf(shaped + _cell_wobble(Vector2i(x, y)) * 0.12 - 0.04, 0.0, 1.0)
				var idx := y * map_width + x
				mask[idx] = maxf(mask[idx], shaped)


func _splat_path_stamp(
	mask: PackedFloat32Array,
	stamp: Dictionary,
	radius: int,
	strength: float,
	falloff: float,
	map_width: int,
	map_height: int,
) -> void:
	var from_cell: Vector2i = stamp.get("from", stamp.get("center", Vector2i.ZERO))
	var to_cell: Vector2i = stamp.get("to", stamp.get("center", Vector2i.ZERO))
	var steps := maxi(1, int(from_cell.distance_to(to_cell)))
	var r_f := float(radius)
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var cx := int(round(lerpf(float(from_cell.x), float(to_cell.x), t)))
		var cy := int(round(lerpf(float(from_cell.y), float(to_cell.y), t)))
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var x := cx + dx
				var y := cy + dy
				if x < 0 or y < 0 or x >= map_width or y >= map_height:
					continue
				var dist := sqrt(float(dx * dx + dy * dy))
				if dist > r_f:
					continue
				var edge := 1.0 - dist / r_f
				var shaped := pow(maxf(edge, 0.0), falloff) * strength
				var idx := y * map_width + x
				mask[idx] = maxf(mask[idx], shaped)


static func load_demo_or_build(map_width: int, map_height: int, warren_cell: Vector2i) -> MapAuthoringData:
	## Always rebuild relative to warren_cell so composition stays centered.
	## DEMO_RESOURCE_PATH remains a hand-edit override if assigned on MapConfig.
	return build_demo_layout(map_width, map_height, warren_cell)


static func build_demo_layout(map_width: int, map_height: int, warren_cell: Vector2i) -> MapAuthoringData:
	var data := MapAuthoringData.new()
	var cx := warren_cell.x + 1
	var cy := warren_cell.y + 1
	var edge_inset := maxi(8, mini(map_width, map_height) / 28)

	## Irregular lumpy clearing — overlapping offset blobs, not one clean disk.
	data.clearing_stamps = [
		_stamp(Vector2i(cx, cy), maxi(11, map_width / 28), 1.0, 1.6, "warren_core"),
		_stamp(Vector2i(cx - 7, cy + 3), 9, 0.92, 1.8, "lump_sw"),
		_stamp(Vector2i(cx + 8, cy - 4), 10, 0.9, 1.7, "lump_ne"),
		_stamp(Vector2i(cx + 5, cy + 7), 8, 0.88, 1.9, "lump_se"),
		_stamp(Vector2i(cx - 6, cy - 6), 8, 0.85, 1.8, "lump_nw"),
		_stamp(Vector2i(cx + 2, cy - 9), 7, 0.72, 2.0, "trample_n"),
		_stamp(Vector2i(cx - 3, cy + 10), 7, 0.7, 2.0, "trample_s"),
		_stamp(Vector2i(cx, cy), maxi(18, map_width / 16), 0.42, 2.4, "camp_soft_edge"),
	]

	## Muddy path arms toward early wood / food / stone (also used as road bias).
	data.road_stamps = [
		_path_stamp(Vector2i(cx, cy), Vector2i(cx - 20, cy + 16), 3, 0.95, "path_wood"),
		_path_stamp(Vector2i(cx, cy), Vector2i(cx + 22, cy - 14), 3, 0.92, "path_food"),
		_path_stamp(Vector2i(cx, cy), Vector2i(cx + 18, cy + 20), 3, 0.9, "path_stone"),
		## Main raid approach from east edge toward camp (stops short via corridor planner).
		_path_stamp(Vector2i(map_width - 4, cy + 8), Vector2i(cx + 14, cy + 2), 4, 1.0, "raid_east"),
		_stamp(Vector2i(cx + 28, cy + 2), 6, 0.85, 1.2, "raid_near"),
	]

	data.forest_stamps = [
		_stamp(Vector2i(cx, edge_inset + 18), maxi(40, map_width / 7), 0.95, 2.0, "north_band"),
		_stamp(Vector2i(cx, map_height - edge_inset - 18), maxi(40, map_width / 7), 0.95, 2.0, "south_band"),
		_stamp(Vector2i(edge_inset + 18, cy), maxi(40, map_width / 7), 0.95, 2.0, "west_band"),
		_stamp(Vector2i(map_width - edge_inset - 18, cy), maxi(40, map_width / 7), 0.95, 2.0, "east_band"),
		_stamp(Vector2i(cx - 38, cy - 28), 22, 0.78, 1.6, "grove_nw"),
		_stamp(Vector2i(cx + 42, cy - 32), 24, 0.82, 1.6, "grove_ne"),
		_stamp(Vector2i(cx - 36, cy + 34), 22, 0.76, 1.6, "grove_sw"),
		_stamp(Vector2i(cx + 40, cy + 30), 24, 0.8, 1.6, "grove_se"),
		_stamp(Vector2i(cx - 22, cy + 8), 14, 0.55, 1.4, "wood_pocket_near"),
		_stamp(Vector2i(cx + 24, cy - 10), 12, 0.5, 1.4, "wood_pocket_near_b"),
	]

	## Readable resource pockets: early wood/food/stone + farther gold/scrap.
	data.resource_stamps = [
		_stamp(Vector2i(cx - 18, cy + 14), 8, 1.0, 1.4, "wood"),
		_stamp(Vector2i(cx - 14, cy - 16), 7, 0.95, 1.4, "wood"),
		_stamp(Vector2i(cx + 16, cy + 12), 7, 0.9, 1.4, "wood"),
		_stamp(Vector2i(cx + 20, cy - 12), 9, 1.0, 1.5, "food"),
		_stamp(Vector2i(cx - 10, cy + 22), 8, 0.92, 1.5, "food"),
		_stamp(Vector2i(cx + 16, cy + 18), 10, 0.95, 1.5, "stone"),
		_stamp(Vector2i(cx - 28, cy - 22), 9, 0.9, 1.5, "stone"),
		_stamp(Vector2i(cx + 48, cy - 30), 10, 0.88, 1.4, "gold"),
		_stamp(Vector2i(cx + 52, cy + 8), 8, 0.8, 1.4, "ruin"),
	]

	data.edge_forest_enabled = true
	data.tree_density_multiplier = 1.45
	data.bush_density_multiplier = 1.15
	data.mushroom_density_multiplier = 1.2
	data.rock_density_multiplier = 1.1
	data.grass_density_multiplier = 1.1
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


## Approximate a path as a chain of circular stamps from a→b.
static func _path_stamp(
	from_cell: Vector2i,
	to_cell: Vector2i,
	radius: int,
	strength: float,
	tag: String,
) -> Dictionary:
	## Stored as a single stamp at midpoint; sample_road_strength expands via polyline helper.
	return {
		"center": Vector2i((from_cell.x + to_cell.x) / 2, (from_cell.y + to_cell.y) / 2),
		"radius": radius,
		"strength": strength,
		"falloff": 1.2,
		"tag": tag,
		"from": from_cell,
		"to": to_cell,
		"is_path": true,
	}


func sample_stamp_mask(cell: Vector2i, stamps: Array[Dictionary]) -> float:
	var peak := 0.0
	for stamp in stamps:
		var strength: float = float(stamp.get("strength", 0.0))
		var falloff: float = maxf(float(stamp.get("falloff", 1.5)), 0.01)
		var radius: int = int(stamp.get("radius", 0))
		if radius <= 0:
			continue
		var dist := _stamp_distance(cell, stamp)
		if dist > float(radius):
			continue
		var edge := 1.0 - dist / float(radius)
		var shaped := pow(maxf(edge, 0.0), falloff) * strength
		peak = maxf(peak, shaped)
	return clampf(peak, 0.0, 1.0)


func _stamp_distance(cell: Vector2i, stamp: Dictionary) -> float:
	if bool(stamp.get("is_path", false)):
		var from_cell: Vector2i = stamp.get("from", stamp.get("center", Vector2i.ZERO))
		var to_cell: Vector2i = stamp.get("to", stamp.get("center", Vector2i.ZERO))
		return _dist_point_to_segment(Vector2(cell), Vector2(from_cell), Vector2(to_cell))
	var center: Vector2i = stamp.get("center", Vector2i.ZERO)
	return Vector2(cell).distance_to(Vector2(center))


func _dist_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq <= 0.0001:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return p.distance_to(a + ab * t)


func sample_clearing_strength(cell: Vector2i) -> float:
	if _clearing_mask.size() > 0 and _mask_width > 0:
		if cell.x < 0 or cell.y < 0 or cell.x >= _mask_width or cell.y >= _mask_height:
			return 0.0
		return _clearing_mask[cell.y * _mask_width + cell.x]
	return sample_stamp_mask(cell, clearing_stamps)


## Soft irregular clearing for terrain classification (lumpy, not a hard disk).
func sample_clearing_for_terrain(cell: Vector2i) -> float:
	return sample_clearing_strength(cell)


func _cell_wobble(cell: Vector2i) -> float:
	var h := int(cell.x * 73856093) ^ int(cell.y * 19349663)
	h = (h ^ (h >> 13)) & 0xFFFF
	return (float(h) / 65535.0) * 2.0 - 1.0


func is_in_road_or_approach_lane(cell: Vector2i) -> bool:
	return sample_road_strength(cell) >= 0.35


func sample_road_strength(cell: Vector2i) -> float:
	if _road_mask.size() > 0 and _mask_width > 0:
		if cell.x < 0 or cell.y < 0 or cell.x >= _mask_width or cell.y >= _mask_height:
			return 0.0
		return _road_mask[cell.y * _mask_width + cell.x]
	return sample_stamp_mask(cell, road_stamps)


func sample_forest_density(cell: Vector2i, terrain_class: Defs.TerrainClass) -> float:
	## Legacy entry — prefer `sample_forest_density_for_plan` when MapPlan is available.
	var clearing := sample_clearing_strength(cell)
	if clearing >= 0.55:
		return 0.0
	if is_in_road_or_approach_lane(cell):
		return _terrain_forest_base(terrain_class) * 0.08 * tree_density_multiplier
	var base := _terrain_forest_base(terrain_class)
	var stamp_boost := sample_stamp_mask(cell, forest_stamps)
	var density := (base + stamp_boost * 0.9) * tree_density_multiplier
	density *= 1.0 - clearing * 0.95
	return clampf(density, 0.0, 1.35)


func sample_forest_density_for_plan(cell: Vector2i, plan: MapPlan, terrain_class: Defs.TerrainClass) -> float:
	var clearing := sample_clearing_strength(cell)
	if clearing >= 0.55:
		return 0.0
	if plan != null and (plan.main_raid_path_cells.has(cell) or plan.approach_corridor_cells.has(cell)):
		return 0.0
	if is_in_road_or_approach_lane(cell):
		return _terrain_forest_base(terrain_class) * 0.08 * tree_density_multiplier

	var base := _terrain_forest_base(terrain_class)
	var stamp_boost := sample_stamp_mask(cell, forest_stamps)
	var edge_boost := edge_forest_boost_for_map(cell, plan.width, plan.height)
	var density := (base + stamp_boost * 0.9 + edge_boost * 0.85) * tree_density_multiplier
	density *= 1.0 - clearing * 0.95
	return clampf(density, 0.0, 1.45)


func sample_resource_bias(cell: Vector2i, kind: Defs.ResourceKind) -> float:
	var bias := 1.0
	for stamp in resource_stamps:
		var tag := str(stamp.get("tag", "")).to_lower()
		var mask := sample_stamp_mask(cell, [stamp])
		if mask <= 0.01:
			continue
		match kind:
			Defs.ResourceKind.WOOD:
				if tag == "wood":
					bias += mask * 5.0
			Defs.ResourceKind.FOOD:
				if tag == "food" or tag == "mushroom":
					bias += mask * 4.5
			Defs.ResourceKind.STONE:
				if tag == "stone" or tag == "rock":
					bias += mask * 4.5
			Defs.ResourceKind.GOLD:
				if tag == "gold" or tag == "ruin":
					bias += mask * 5.5
			_:
				pass
	return bias


func resource_pocket_centers(kind_tag: String) -> Array[Vector2i]:
	var centers: Array[Vector2i] = []
	var tag_l := kind_tag.to_lower()
	for stamp in resource_stamps:
		var tag := str(stamp.get("tag", "")).to_lower()
		if tag == tag_l or (tag_l == "food" and tag == "mushroom") or (tag_l == "stone" and tag == "rock"):
			centers.append(stamp.get("center", Vector2i.ZERO))
	return centers


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
	var band := 18.0
	if dist_edge > band:
		return 0.0
	return (1.0 - dist_edge / band) * 1.0


func is_in_border_ring(cell: Vector2i, map_width: int, map_height: int, depth: int = 6) -> bool:
	return _dist_to_rect_edge(cell, map_width, map_height) <= float(depth)


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
