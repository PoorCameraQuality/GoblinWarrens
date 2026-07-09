class_name TerrainClassifier
extends RefCounted

## Per-tile terrain class from height + slope + camp/warren zones.


static func classify_grid(
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
	config: MapConfig,
	warren_cell: Vector2i,
) -> Array:
	var tile_w: int = config.width
	var tile_h: int = config.height
	var min_h := INF
	var max_h := -INF
	for value in heights:
		min_h = minf(min_h, value)
		max_h = maxf(max_h, value)
	var height_span := maxf(max_h - min_h, 0.001)

	var rows: Array = []
	for y in range(tile_h):
		var row: Array = []
		row.resize(tile_w)
		for x in range(tile_w):
			row[x] = _classify_cell(
				Vector2i(x, y),
				heights,
				point_w,
				point_h,
				min_h,
				height_span,
				config,
				warren_cell,
			)
		rows.append(row)
	return rows


static func is_walkable(terrain_class: Defs.TerrainClass) -> bool:
	return terrain_class != Defs.TerrainClass.CLIFF


static func is_buildable(terrain_class: Defs.TerrainClass) -> bool:
	match terrain_class:
		Defs.TerrainClass.MUD_CLEARING, Defs.TerrainClass.MOSS, Defs.TerrainClass.MUD_MOSSY, Defs.TerrainClass.WARREN_GROUND:
			return true
		_:
			return false


static func class_color(terrain_class: Defs.TerrainClass) -> Color:
	match terrain_class:
		Defs.TerrainClass.MUD_CLEARING:
			return Color(0.52, 0.40, 0.26)
		Defs.TerrainClass.MOSS:
			return Color(0.28, 0.42, 0.22)
		Defs.TerrainClass.FOREST_FLOOR:
			return Color(0.18, 0.30, 0.14)
		Defs.TerrainClass.ROCKY_SLOPE:
			return Color(0.42, 0.38, 0.34)
		Defs.TerrainClass.MUD_MOSSY:
			return Color(0.34, 0.36, 0.22)
		Defs.TerrainClass.CLIFF:
			return Color(0.22, 0.22, 0.24)
		Defs.TerrainClass.WARREN_GROUND:
			return Color(0.46, 0.28, 0.20)
		_:
			return Color(0.3, 0.3, 0.3)


static func _classify_cell(
	cell: Vector2i,
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
	min_h: float,
	height_span: float,
	config: MapConfig,
	warren_cell: Vector2i,
) -> Defs.TerrainClass:
	if _inside_camp_radius(cell, warren_cell, config):
		return Defs.TerrainClass.MUD_CLEARING
	if _inside_warren_ring(cell, warren_cell, config.warren_footprint):
		return Defs.TerrainClass.WARREN_GROUND

	var slope_deg := _cell_slope_degrees(cell, heights, point_w, point_h)
	var norm_height := _cell_norm_height(cell, heights, point_w, point_h, min_h, height_span)

	if slope_deg > Constants.MAPGEN_CLIFF_ANGLE_DEG:
		return Defs.TerrainClass.CLIFF
	if slope_deg > Constants.MAPGEN_ROCKY_ANGLE_DEG:
		return Defs.TerrainClass.ROCKY_SLOPE
	if norm_height > Constants.MAPGEN_FOREST_HEIGHT_TOP:
		return Defs.TerrainClass.FOREST_FLOOR
	if norm_height < Constants.MAPGEN_LOWLAND_HEIGHT_TOP:
		return Defs.TerrainClass.MUD_MOSSY
	return Defs.TerrainClass.MOSS


static func _inside_camp_radius(cell: Vector2i, warren_cell: Vector2i, config: MapConfig) -> bool:
	var camp_center := Vector2(warren_cell) + Vector2(config.warren_footprint) * 0.5
	return Vector2(cell).distance_to(camp_center) <= float(config.camp_flat_radius)


static func _inside_warren_ring(cell: Vector2i, warren_cell: Vector2i, footprint: Vector2i) -> bool:
	for dx in range(-1, footprint.x + 1):
		for dy in range(-1, footprint.y + 1):
			if dx < 0 or dy < 0 or dx >= footprint.x or dy >= footprint.y:
				if cell == warren_cell + Vector2i(dx, dy):
					return true
	return false


static func _cell_slope_degrees(
	cell: Vector2i,
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
) -> float:
	var h00 := _height_at_point(cell.x, cell.y, heights, point_w, point_h)
	var h10 := _height_at_point(cell.x + 1, cell.y, heights, point_w, point_h)
	var h01 := _height_at_point(cell.x, cell.y + 1, heights, point_w, point_h)
	var dhdx := h10 - h00
	var dhdz := h01 - h00
	var slope_rad := atan(sqrt(dhdx * dhdx + dhdz * dhdz) / Constants.TILE_SIZE)
	return rad_to_deg(slope_rad)


static func _cell_norm_height(
	cell: Vector2i,
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
	min_h: float,
	height_span: float,
) -> float:
	var h00 := _height_at_point(cell.x, cell.y, heights, point_w, point_h)
	var h10 := _height_at_point(cell.x + 1, cell.y, heights, point_w, point_h)
	var h01 := _height_at_point(cell.x, cell.y + 1, heights, point_w, point_h)
	var h11 := _height_at_point(cell.x + 1, cell.y + 1, heights, point_w, point_h)
	var avg := (h00 + h10 + h01 + h11) * 0.25
	return clampf((avg - min_h) / height_span, 0.0, 1.0)


static func _height_at_point(
	x: int,
	z: int,
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
) -> float:
	var cx := clampi(x, 0, point_w - 1)
	var cz := clampi(z, 0, point_h - 1)
	return heights[cz * point_w + cx]
