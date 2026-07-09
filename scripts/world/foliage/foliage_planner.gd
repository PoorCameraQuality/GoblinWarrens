class_name FoliagePlanner
extends RefCounted

## Builds a FoliagePlan from MapPlan terrain classes + composition masks.
## Grass is visual-only; roads/clearings/camp/corridors suppress density.
## Chunk-sampled (not full 350x350 density bake) for generation speed.

const _FoliagePlanScript := preload("res://scripts/world/foliage/foliage_plan.gd")
## Samples per chunk axis when estimating density (4 => 16 probes).
const _CHUNK_SAMPLE_AXIS := 4


static func plan(map_plan: MapPlan, config: MapConfig, rng: MapRng):
	var foliage = _FoliagePlanScript.new()
	foliage.width = map_plan.width
	foliage.height = map_plan.height
	foliage.chunk_size = int(Constants.FOLIAGE_CHUNK_SIZE_M)
	## Sparse density buffer: only store cells we actually probe for chunks/ambient.
	## Renderer samples density via _probe_density() using the same rules.
	foliage.density = PackedFloat32Array()
	foliage.style_ids = PackedByteArray()
	foliage.stats = {}

	var authoring = map_plan.authoring_data
	var blocker_cells := _blocker_cells(map_plan)
	var grass_mult := 1.0
	if authoring != null:
		grass_mult = clampf(float(authoring.grass_density_multiplier), 0.0, 2.0)

	foliage.blocker_cells = blocker_cells
	_build_chunks(foliage, map_plan, config, authoring, blocker_cells, grass_mult, rng)
	_build_ambient_zones(foliage, map_plan, config, authoring, blocker_cells, grass_mult, rng)

	foliage.stats = {
		"grass_cells": int(foliage.stats.get("grass_cells", 0)),
		"avg_density": float(foliage.stats.get("avg_density", 0.0)),
		"chunk_count": foliage.chunks.size(),
		"instance_estimate": _estimate_instances(foliage),
		"ambient_zones": foliage.ambient_zones.size(),
		"ambient_by_type": _ambient_counts(foliage),
		"probe_mode": true,
	}
	return foliage


static func probe_density(
	map_plan: MapPlan,
	config: MapConfig,
	cell: Vector2i,
	blocker_cells: Dictionary = {},
) -> Dictionary:
	## Returns {density: float, style: int}. Used by GrassFieldRenderer.
	if cell.x < 0 or cell.y < 0 or cell.x >= map_plan.width or cell.y >= map_plan.height:
		return {"density": 0.0, "style": _FoliagePlanScript.GrassStyle.NONE}
	var authoring = map_plan.authoring_data
	var grass_mult := 1.0
	if authoring != null:
		grass_mult = clampf(float(authoring.grass_density_multiplier), 0.0, 2.0)
	return _probe_cell(map_plan, config, authoring, blocker_cells, grass_mult, cell, config.seed)


static func _probe_cell(
	map_plan: MapPlan,
	config: MapConfig,
	authoring,
	blocker_cells: Dictionary,
	grass_mult: float,
	cell: Vector2i,
	seed: int,
) -> Dictionary:
	var none := {"density": 0.0, "style": _FoliagePlanScript.GrassStyle.NONE}
	var terrain_class: Defs.TerrainClass = map_plan.tile_classes[cell.y][cell.x]
	var base := _base_density(terrain_class)
	if base <= 0.0:
		return none
	var style := _style_for_class(terrain_class)
	if style == _FoliagePlanScript.GrassStyle.NONE:
		return none
	if blocker_cells.has(cell):
		return none
	if _inside_camp(cell, map_plan.warren_cell, config):
		return none
	if map_plan.approach_corridor_cells.has(cell):
		return none
	if map_plan.main_raid_path_cells.has(cell):
		return none
	if authoring != null:
		if float(authoring.sample_road_strength(cell)) >= 0.35:
			return none
		var clearing_s: float = float(authoring.sample_clearing_strength(cell))
		if clearing_s >= 0.55:
			return none
		if clearing_s >= 0.35:
			base *= 0.22
			style = _FoliagePlanScript.GrassStyle.DRY_TUFT
	if _in_footprint(cell, map_plan.warren_cell, config.warren_footprint):
		return none
	if _in_footprint(cell, map_plan.storehouse_cell, config.warren_footprint):
		return none
	base *= grass_mult
	var jitter := 0.85 + 0.3 * _hash01(cell.x, cell.y, seed)
	base = clampf(base * jitter, 0.0, 1.0)
	return {"density": base, "style": style}


static func _hash01(x: int, y: int, seed: int) -> float:
	var n := seed * 374761393 + x * 668265263 + y * 2147483647
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0x7fffffff) / 2147483647.0


static func _base_density(terrain_class: Defs.TerrainClass) -> float:
	match terrain_class:
		Defs.TerrainClass.MOSS:
			return 0.78
		Defs.TerrainClass.FOREST_FLOOR:
			return 0.38
		Defs.TerrainClass.MUD_MOSSY:
			return 0.52
		Defs.TerrainClass.ROCKY_SLOPE:
			return 0.16
		_:
			return 0.0


static func _style_for_class(terrain_class: Defs.TerrainClass) -> int:
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


static func _blocker_cells(map_plan: MapPlan) -> Dictionary:
	var out := {}
	for entry in map_plan.prop_placements:
		if entry == null:
			continue
		if entry.blocks_movement or entry.resource_kind >= 0:
			out[entry.grid_cell] = true
	return out


static func _inside_camp(cell: Vector2i, warren_cell: Vector2i, config: MapConfig) -> bool:
	var camp_center := Vector2(warren_cell) + Vector2(config.warren_footprint) * 0.5
	return Vector2(cell).distance_to(camp_center) <= float(maxi(6, config.camp_flat_radius / 3))


static func _in_footprint(cell: Vector2i, origin: Vector2i, footprint: Vector2i) -> bool:
	return (
		cell.x >= origin.x
		and cell.y >= origin.y
		and cell.x < origin.x + footprint.x
		and cell.y < origin.y + footprint.y
	)


static func _build_chunks(
	foliage,
	map_plan: MapPlan,
	config: MapConfig,
	authoring,
	blocker_cells: Dictionary,
	grass_mult: float,
	rng: MapRng,
) -> void:
	var cs: int = int(foliage.chunk_size)
	var chunks_x := int(ceili(float(foliage.width) / float(cs)))
	var chunks_y := int(ceili(float(foliage.height) / float(cs)))
	var grass_cells := 0
	var density_sum := 0.0
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
					var probe: Dictionary = _probe_cell(
						map_plan, config, authoring, blocker_cells, grass_mult, cell, config.seed
					)
					probes += 1
					var d: float = float(probe["density"])
					if d > 0.0:
						sum += d
						hits += 1
						var style: int = int(probe["style"])
						style_votes[style] = int(style_votes.get(style, 0)) + 1
					x += step
				y += step
			if hits == 0 or probes == 0:
				continue
			var avg := sum / float(probes)
			if avg < Constants.FOLIAGE_MIN_CHUNK_DENSITY:
				continue
			grass_cells += hits
			density_sum += sum
			var dominant_style := _FoliagePlanScript.GrassStyle.SHORT_MOSS
			var best_votes := -1
			for style_key in style_votes.keys():
				var votes: int = int(style_votes[style_key])
				if votes > best_votes:
					best_votes = votes
					dominant_style = int(style_key)
			var short_count := int(
				round(
					float(Constants.FOLIAGE_SHORT_MAX_PER_CHUNK)
					* clampf(avg / 0.55, 0.15, 1.0)
				)
			)
			var tall_count := 0
			if (
				dominant_style == _FoliagePlanScript.GrassStyle.WET_REED
				or dominant_style == _FoliagePlanScript.GrassStyle.SHORT_MOSS
			):
				tall_count = int(
					round(
						float(Constants.FOLIAGE_TALL_MAX_PER_CHUNK)
						* clampf(avg / 0.7, 0.0, 1.0)
					)
				)
			foliage.chunks.append(
				{
					"origin": origin,
					"size": cs,
					"avg_density": avg,
					"style": dominant_style,
					"short_count": short_count,
					"tall_count": tall_count,
					"seed": int(rng.randi_range(1, 1_000_000_000)),
					"chunk_id": Vector2i(cx, cy),
				}
			)
	foliage.stats["grass_cells"] = grass_cells
	foliage.stats["avg_density"] = density_sum / float(maxi(1, grass_cells))


static func _build_ambient_zones(
	foliage,
	map_plan: MapPlan,
	config: MapConfig,
	authoring,
	blocker_cells: Dictionary,
	grass_mult: float,
	rng: MapRng,
) -> void:
	var zones: Array = []
	for entry in map_plan.prop_placements:
		if entry == null:
			continue
		if entry.resource_kind == Defs.ResourceKind.FOOD:
			zones.append(
				_zone(
					entry.grid_cell,
					4.5,
					_FoliagePlanScript.AmbientEffect.FIREFLIES,
					"night",
					0.7,
					rng,
				)
			)
			if rng.roll(0.45):
				zones.append(
					_zone(
						entry.grid_cell,
						3.5,
						_FoliagePlanScript.AmbientEffect.SPORES,
						"any",
						0.55,
						rng,
					)
				)
		elif "mushroom" in str(entry.scene_path).to_lower() and entry.resource_kind < 0:
			if rng.roll(0.35):
				zones.append(
					_zone(
						entry.grid_cell,
						3.0,
						_FoliagePlanScript.AmbientEffect.FIREFLIES,
						"night",
						0.5,
						rng,
					)
				)

	for _i in range(28):
		var cell := Vector2i(
			rng.randi_range(8, map_plan.width - 9),
			rng.randi_range(8, map_plan.height - 9),
		)
		var probe: Dictionary = _probe_cell(
			map_plan, config, authoring, blocker_cells, grass_mult, cell, config.seed
		)
		if float(probe["density"]) < 0.45:
			continue
		if map_plan.tile_classes[cell.y][cell.x] != Defs.TerrainClass.MOSS:
			continue
		zones.append(
			_zone(cell, 5.0, _FoliagePlanScript.AmbientEffect.BUTTERFLIES, "day", 0.55, rng)
		)

	for _i in range(18):
		var cell := Vector2i(
			rng.randi_range(8, map_plan.width - 9),
			rng.randi_range(8, map_plan.height - 9),
		)
		if map_plan.tile_classes[cell.y][cell.x] != Defs.TerrainClass.MUD_MOSSY:
			continue
		if map_plan.approach_corridor_cells.has(cell):
			continue
		zones.append(_zone(cell, 4.0, _FoliagePlanScript.AmbientEffect.GNATS, "day", 0.45, rng))

	while zones.size() > Constants.FOLIAGE_AMBIENT_MAX_ZONES:
		zones.remove_at(zones.size() - 1)
	foliage.ambient_zones = zones


static func _zone(
	center: Vector2i,
	radius: float,
	effect: int,
	tod: String,
	intensity: float,
	rng: MapRng,
) -> Dictionary:
	return {
		"center": center,
		"radius": radius,
		"effect": effect,
		"time_of_day": tod,
		"intensity": intensity,
		"seed": int(rng.randi_range(1, 1_000_000_000)),
	}


static func _estimate_instances(foliage) -> int:
	var total := 0
	for chunk in foliage.chunks:
		total += int(chunk.get("short_count", 0))
		total += int(chunk.get("tall_count", 0))
	return total


static func _ambient_counts(foliage) -> Dictionary:
	var counts := {
		"butterflies": 0,
		"fireflies": 0,
		"gnats": 0,
		"spores": 0,
	}
	for zone in foliage.ambient_zones:
		match int(zone.get("effect", -1)):
			_FoliagePlanScript.AmbientEffect.BUTTERFLIES:
				counts["butterflies"] = int(counts["butterflies"]) + 1
			_FoliagePlanScript.AmbientEffect.FIREFLIES:
				counts["fireflies"] = int(counts["fireflies"]) + 1
			_FoliagePlanScript.AmbientEffect.GNATS:
				counts["gnats"] = int(counts["gnats"]) + 1
			_FoliagePlanScript.AmbientEffect.SPORES:
				counts["spores"] = int(counts["spores"]) + 1
	return counts
