extends RefCounted

## Compiles decorative grass scatter from baked semantic layers (Phase 5).
##
## STABILITY NOTE: kept as one compile() entry for headless smoke reliability.
## See docs/technical/GODOT_HEADLESS_PITFALLS.md

const NO_SCATTER_THRESHOLD := 250
const _CHUNK_SAMPLE_AXIS := 4
const _FoliagePlanScript := preload("res://scripts/world/foliage/foliage_plan.gd")


static func compile(map_root: String, target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)) -> Variant:
	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var Compiler = load("res://scripts/world/map/grid_compiler.gd")
	var definition = Factory.load_from_map_root(map_root, target_size)
	if definition == null:
		return null
	var grid = Compiler.compile_map(map_root, target_size)
	if grid == null:
		return null
	return compile_from_definition(definition, grid)


static func compile_from_definition(definition, grid) -> Variant:
	if definition == null or grid == null:
		return null

	var density_path: String = definition.get_layer_path("foliage_density")
	var scatter_path: String = definition.get_layer_path("no_scatter")
	if density_path.is_empty() or scatter_path.is_empty():
		push_error("DecorativeScatterCompiler: missing foliage_density or no_scatter layer")
		return null

	var density_img := Image.load_from_file(ProjectSettings.globalize_path(density_path))
	var scatter_img := Image.load_from_file(ProjectSettings.globalize_path(scatter_path))
	if density_img == null or scatter_img == null:
		return null
	density_img.convert(Image.FORMAT_RGBA8)
	scatter_img.convert(Image.FORMAT_RGBA8)

	var width: int = grid.width
	var height: int = grid.height
	if density_img.get_width() != width or density_img.get_height() != height:
		push_error("DecorativeScatterCompiler: layer size mismatch")
		return null

	var foliage = _FoliagePlanScript.new()
	foliage.width = width
	foliage.height = height
	foliage.chunk_size = int(Constants.FOLIAGE_CHUNK_SIZE_M)
	foliage.density.resize(width * height)
	foliage.style_ids.resize(width * height)

	var seed_foliage: int = int(definition.seed_foliage)
	var grass_cells := 0
	var suppressed_scatter := 0
	var density_sum := 0.0

	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var idx := y * width + x
			var probe := _probe_cell(grid, density_img, scatter_img, cell, seed_foliage)
			var d: float = float(probe["density"])
			var style: int = int(probe["style"])
			foliage.density[idx] = d
			foliage.style_ids[idx] = style
			if d > 0.0:
				grass_cells += 1
				density_sum += d
			if int(probe.get("scatter_blocked", 0)) != 0:
				suppressed_scatter += 1

	_build_chunks(foliage, seed_foliage)
	foliage.stats = {
		"grass_cells": grass_cells,
		"avg_density": density_sum / float(maxi(1, grass_cells)),
		"chunk_count": foliage.chunks.size(),
		"instance_estimate": _estimate_instances(foliage),
		"ambient_zones": foliage.ambient_zones.size(),
		"authored": true,
		"map_id": str(definition.map_id),
		"seed_foliage": seed_foliage,
		"scatter_suppressed_cells": suppressed_scatter,
		"probe_mode": false,
	}
	return foliage


static func _probe_cell(
	grid,
	density_img: Image,
	scatter_img: Image,
	cell: Vector2i,
	seed_foliage: int,
) -> Dictionary:
	var none := {"density": 0.0, "style": _FoliagePlanScript.GrassStyle.NONE, "scatter_blocked": 0}
	if not grid.is_walkable_cell(cell):
		return none
	if scatter_img.get_pixel(cell.x, cell.y).r8 >= NO_SCATTER_THRESHOLD:
		return {"density": 0.0, "style": _FoliagePlanScript.GrassStyle.NONE, "scatter_blocked": 1}
	var terrain_class: int = grid.terrain_class_at(cell)
	var style := _style_for_class(terrain_class)
	if style == _FoliagePlanScript.GrassStyle.NONE:
		return none
	var authored: float = float(density_img.get_pixel(cell.x, cell.y).r8) / 255.0
	if authored <= 0.0:
		return none
	var terrain_scale := _terrain_density_scale(terrain_class)
	var jitter := 0.85 + 0.3 * _hash01(cell.x, cell.y, seed_foliage)
	var d := clampf(authored * terrain_scale * jitter, 0.0, 1.0)
	return {"density": d, "style": style, "scatter_blocked": 0}


static func _terrain_density_scale(terrain_class: int) -> float:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return 1.0
		Defs.TerrainClass.FOREST_FLOOR:
			return 0.85
		Defs.TerrainClass.MUD_MOSSY:
			return 0.9
		Defs.TerrainClass.ROCKY_SLOPE:
			return 0.45
		_:
			return 0.0


static func _style_for_class(terrain_class: int) -> int:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return _FoliagePlanScript.GrassStyle.SHORT_MOSS
		Defs.TerrainClass.FOREST_FLOOR:
			return _FoliagePlanScript.GrassStyle.SHADE_SPARSE
		Defs.TerrainClass.MUD_MOSSY:
			return _FoliagePlanScript.GrassStyle.WET_REED
		Defs.TerrainClass.ROCKY_SLOPE:
			return _FoliagePlanScript.GrassStyle.DRY_TUFT
		_:
			return _FoliagePlanScript.GrassStyle.NONE


static func _hash01(x: int, y: int, seed: int) -> float:
	var n := seed * 374761393 + x * 668265263 + y * 2147483647
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7fffffff) / 2147483647.0


static func _build_chunks(foliage, seed_foliage: int) -> void:
	var cs: int = int(foliage.chunk_size)
	var chunks_x := int(ceili(float(foliage.width) / float(cs)))
	var chunks_y := int(ceili(float(foliage.height) / float(cs)))
	var step := maxi(1, cs / _CHUNK_SAMPLE_AXIS)
	for cy in range(chunks_y):
		for cx in range(chunks_x):
			var origin := Vector2i(cx * cs, cy * cs)
			var sum := 0.0
			var probes := 0
			var hits := 0
			var style_votes := {}
			var x_max := mini(origin.x + cs, foliage.width)
			var y_max := mini(origin.y + cs, foliage.height)
			var y := origin.y
			while y < y_max:
				var x := origin.x
				while x < x_max:
					var cell := Vector2i(x, y)
					var idx: int = foliage.cell_index(cell)
					var d: float = foliage.density[idx]
					probes += 1
					if d > 0.0:
						sum += d
						hits += 1
						var style: int = int(foliage.style_ids[idx])
						style_votes[style] = int(style_votes.get(style, 0)) + 1
					x += step
				y += step
			if hits == 0 or probes == 0:
				continue
			var avg := sum / float(probes)
			if avg < Constants.FOLIAGE_MIN_CHUNK_DENSITY:
				continue
			var dominant_style := _FoliagePlanScript.GrassStyle.SHORT_MOSS
			var best_votes := -1
			for style_key in style_votes.keys():
				var votes: int = int(style_votes[style_key])
				if votes > best_votes:
					best_votes = votes
					dominant_style = int(style_key)
			var short_count := int(
				round(float(Constants.FOLIAGE_SHORT_MAX_PER_CHUNK) * clampf(avg / 0.55, 0.15, 1.0))
			)
			var tall_count := 0
			if (
				dominant_style == _FoliagePlanScript.GrassStyle.WET_REED
				or dominant_style == _FoliagePlanScript.GrassStyle.SHORT_MOSS
			):
				tall_count = int(
					round(float(Constants.FOLIAGE_TALL_MAX_PER_CHUNK) * clampf(avg / 0.7, 0.0, 1.0))
				)
			var chunk_seed := int(_hash01(cx, cy, seed_foliage) * 1_000_000_000.0)
			foliage.chunks.append(
				{
					"origin": origin,
					"size": cs,
					"avg_density": avg,
					"style": dominant_style,
					"short_count": short_count,
					"tall_count": tall_count,
					"seed": chunk_seed,
					"chunk_id": Vector2i(cx, cy),
				}
			)


static func _estimate_instances(foliage) -> int:
	var total := 0
	for chunk in foliage.chunks:
		total += int(chunk.get("short_count", 0))
		total += int(chunk.get("tall_count", 0))
	return total
