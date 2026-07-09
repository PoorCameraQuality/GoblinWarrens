class_name TerrainBlendMapBuilder
extends RefCounted

## Generates a per-cell blend control map from terrain classes (rendering only).

const BLEND_WIDTH_CELLS := 3.0 ## transition width in meters (1 cell = 1 m)

const _OFFSETS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
	Vector2i(2, 0), Vector2i(-2, 0), Vector2i(0, 2), Vector2i(0, -2),
	Vector2i(2, 1), Vector2i(2, -1), Vector2i(-2, 1), Vector2i(-2, -1),
	Vector2i(1, 2), Vector2i(-1, 2), Vector2i(1, -2), Vector2i(-1, -2),
	Vector2i(2, 2), Vector2i(2, -2), Vector2i(-2, 2), Vector2i(-2, -2),
]


static func build(tile_classes: Array, width: int, height: int) -> Dictionary:
	var pair_counts: Dictionary = {}
	var cells_with_blend := 0
	var pixels := PackedByteArray()
	pixels.resize(width * height * 3)
	var offset_count := _OFFSETS.size()

	for y in range(height):
		for x in range(width):
			var primary: Defs.TerrainClass = tile_classes[y][x]
			var secondary: Defs.TerrainClass = primary
			var weight := 0.0
			var min_dist := BLEND_WIDTH_CELLS + 1.0

			for i in offset_count:
				var ox: int = _OFFSETS[i].x
				var oy: int = _OFFSETS[i].y
				var dist: float = sqrt(float(ox * ox + oy * oy))
				if dist > BLEND_WIDTH_CELLS:
					continue
				var nx := x + ox
				var ny := y + oy
				if nx < 0 or ny < 0 or nx >= width or ny >= height:
					continue
				var other: Defs.TerrainClass = tile_classes[ny][nx]
				if other == primary or not _can_soft_blend(primary, other):
					continue
				if dist < min_dist:
					min_dist = dist
					secondary = other

			if min_dist <= BLEND_WIDTH_CELLS:
				var t := 1.0 - (min_dist / BLEND_WIDTH_CELLS)
				weight = t * t
				cells_with_blend += 1
				var pair_key := _pair_key(primary, secondary)
				pair_counts[pair_key] = int(pair_counts.get(pair_key, 0)) + 1

			var idx := (y * width + x) * 3
			pixels[idx] = int(clampi(roundi(float(primary) / 6.0 * 255.0), 0, 255))
			pixels[idx + 1] = int(clampi(roundi(float(secondary) / 6.0 * 255.0), 0, 255))
			pixels[idx + 2] = int(clampi(roundi(weight * 255.0), 0, 255))

	var image := Image.create_from_data(width, height, false, Image.FORMAT_RGB8, pixels)
	var tex := ImageTexture.new()
	tex.set_image(image)
	return {
		"texture": tex,
		"stats": {
			"width": width,
			"height": height,
			"cells_with_blend": cells_with_blend,
			"pair_counts": pair_counts,
			"blend_width_m": BLEND_WIDTH_CELLS,
		},
	}


static func _can_soft_blend(a: Defs.TerrainClass, b: Defs.TerrainClass) -> bool:
	if a == b:
		return false
	if a == Defs.TerrainClass.CLIFF or b == Defs.TerrainClass.CLIFF:
		return false
	if a == Defs.TerrainClass.WARREN_GROUND and b != Defs.TerrainClass.MUD_CLEARING:
		return false
	if b == Defs.TerrainClass.WARREN_GROUND and a != Defs.TerrainClass.MUD_CLEARING:
		return false
	var lo := mini(int(a), int(b))
	var hi := maxi(int(a), int(b))
	if lo == 0 and hi == 1:
		return true
	if lo == 1 and hi == 2:
		return true
	if lo == 1 and hi == 3:
		return true
	if lo == 1 and hi == 4:
		return true
	if lo == 0 and hi == 6:
		return true
	if lo == 2 and hi == 4:
		return true
	return false


static func _pair_key(a: Defs.TerrainClass, b: Defs.TerrainClass) -> String:
	var lo := mini(int(a), int(b))
	var hi := maxi(int(a), int(b))
	return "%d_%d" % [lo, hi]
