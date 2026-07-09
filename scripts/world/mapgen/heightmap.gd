class_name HeightmapGenerator
extends RefCounted

## Layered ridged fBm with valley basins, edge mountains, and camp flattening.


static func generate(config: MapConfig, warren_cell: Vector2i) -> Dictionary:
	var point_w: int = config.width + 1
	var point_h: int = config.height + 1
	var raw := _sample_noise_grid(config, point_w, point_h)
	_flatten_valley_floors(raw, point_w, point_h)
	var camp_center := Vector2(warren_cell) + Vector2(config.warren_footprint) * 0.5
	var camp_height := _mean_height_in_radius(raw, point_w, point_h, camp_center, float(config.camp_blend_radius))
	_flatten_camp(raw, point_w, point_h, camp_center, camp_height, config)
	for _pass in range(Constants.MAPGEN_SMOOTHING_PASSES):
		raw = _smooth_grid(raw, point_w, point_h)
	return {
		"heights": raw,
		"point_width": point_w,
		"point_height": point_h,
	}


static func _sample_noise_grid(config: MapConfig, point_w: int, point_h: int) -> PackedFloat32Array:
	var base_noise := _make_noise(config.seed, Constants.MAPGEN_NOISE_BASE_FREQ)
	var ridge_a := _make_noise(config.seed + 1, Constants.MAPGEN_NOISE_HILL_FREQ)
	var ridge_b := _make_noise(config.seed + 2, Constants.MAPGEN_NOISE_HILL_FREQ_B)
	var detail_noise := _make_noise(config.seed + 3, Constants.MAPGEN_NOISE_DETAIL_FREQ)
	var heights := PackedFloat32Array()
	heights.resize(point_w * point_h)
	for z in range(point_h):
		for x in range(point_w):
			var macro := base_noise.get_noise_2d(float(x), float(z)) * 0.5 + 0.5
			var basin_a := _ridged_valley(ridge_a.get_noise_2d(float(x), float(z)))
			var basin_b := _ridged_valley(ridge_b.get_noise_2d(float(x), float(z)))
			var basin := basin_a * 0.58 + basin_b * 0.42
			var edge_lift := _edge_uplift(x, z, point_w, point_h)
			var detail := detail_noise.get_noise_2d(float(x), float(z))
			var combined := (
				0.18 * macro
				+ 0.92 * basin
				+ edge_lift
				+ Constants.MAPGEN_NOISE_DETAIL_WEIGHT * detail
			)
			heights[z * point_w + x] = config.height_scale * combined
	return heights


static func _ridged_valley(noise_sample: float) -> float:
	var valley := 1.0 - absf(noise_sample)
	return pow(clampf(valley, 0.0, 1.0), Constants.MAPGEN_RIDGE_SHARPNESS)


static func _edge_uplift(x: int, z: int, point_w: int, point_h: int) -> float:
	var nx := float(x) / float(maxi(point_w - 1, 1))
	var nz := float(z) / float(maxi(point_h - 1, 1))
	var edge_x := minf(nx, 1.0 - nx) * 2.0
	var edge_z := minf(nz, 1.0 - nz) * 2.0
	var edge_t := clampf(minf(edge_x, edge_z), 0.0, 1.0)
	return pow(1.0 - edge_t, 1.55) * Constants.MAPGEN_EDGE_UPLIFT


static func _flatten_valley_floors(heights: PackedFloat32Array, point_w: int, point_h: int) -> void:
	for z in range(1, point_h - 1):
		for x in range(1, point_w - 1):
			var idx := z * point_w + x
			var center := heights[idx]
			var local_min := center
			var local_sum := 0.0
			var count := 0
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var sample := heights[(z + dz) * point_w + (x + dx)]
					local_min = minf(local_min, sample)
					local_sum += sample
					count += 1
			var local_avg := local_sum / float(count)
			if center > local_avg * 1.04:
				continue
			heights[idx] = lerpf(center, local_min, Constants.MAPGEN_VALLEY_FLATTEN_BLEND)


static func _make_noise(seed: int, frequency: float) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = frequency
	return noise


static func _mean_height_in_radius(
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
	center: Vector2,
	radius: float,
) -> float:
	var total := 0.0
	var count := 0
	var max_r := int(ceil(radius))
	for z in range(maxi(0, int(center.y) - max_r), mini(point_h, int(center.y) + max_r + 1)):
		for x in range(maxi(0, int(center.x) - max_r), mini(point_w, int(center.x) + max_r + 1)):
			if Vector2(x, z).distance_to(center) > radius:
				continue
			total += heights[z * point_w + x]
			count += 1
	if count <= 0:
		return 0.0
	return total / float(count)


static func _flatten_camp(
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
	center: Vector2,
	camp_height: float,
	config: MapConfig,
) -> void:
	for z in range(point_h):
		for x in range(point_w):
			var dist := Vector2(x, z).distance_to(center)
			if dist <= float(config.camp_flat_radius):
				heights[z * point_w + x] = camp_height
			elif dist <= float(config.camp_blend_radius):
				var t := (dist - float(config.camp_flat_radius)) / float(config.camp_blend_radius - config.camp_flat_radius)
				t = clampf(t, 0.0, 1.0)
				t = t * t * (3.0 - 2.0 * t)
				var natural := heights[z * point_w + x]
				heights[z * point_w + x] = lerpf(camp_height, natural, t)


static func _smooth_grid(heights: PackedFloat32Array, point_w: int, point_h: int) -> PackedFloat32Array:
	var smoothed := PackedFloat32Array()
	smoothed.resize(heights.size())
	for z in range(point_h):
		for x in range(point_w):
			var total := 0.0
			var count := 0
			for dz in range(-1, 2):
				for dx in range(-1, 2):
					var nx := clampi(x + dx, 0, point_w - 1)
					var nz := clampi(z + dz, 0, point_h - 1)
					total += heights[nz * point_w + nx]
					count += 1
			smoothed[z * point_w + x] = total / float(count)
	return smoothed
