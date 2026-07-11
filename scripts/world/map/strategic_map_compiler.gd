extends RefCounted

## Compiles raid entries, enemy camps, and landmarks from baked semantic layers (Phase 8).

const MARKER_THRESHOLD := 128
const RAID_CLUSTER_RADIUS := 6
const ENEMY_CAMP_CLUSTER_RADIUS := 8
const LANDMARK_CLUSTER_RADIUS := 4


static func compile(map_root: String, target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)) -> Variant:
	var Factory = load("res://scripts/world/map/map_definition_factory.gd")
	var definition = Factory.load_from_map_root(map_root, target_size)
	if definition == null:
		return null
	return compile_from_definition(definition)


static func compile_from_definition(definition) -> Variant:
	if definition == null:
		return null
	var raid_path: String = definition.get_layer_path("raid_entry")
	var enemy_path: String = definition.get_layer_path("enemy_camp_zone")
	if raid_path.is_empty() or enemy_path.is_empty():
		push_error("StrategicMapCompiler: missing raid_entry or enemy_camp_zone layer")
		return null
	var raid_img := _load_layer(raid_path)
	var enemy_img := _load_layer(enemy_path)
	if raid_img == null or enemy_img == null:
		return null

	var compiled = load("res://scripts/world/map/compiled_strategic_map.gd").new()
	compiled.map_id = str(definition.map_id)
	compiled.width = definition.grid_width
	compiled.height = definition.grid_height
	compiled.raid_entries = _cluster_markers(
		raid_img,
		"%s/raid" % definition.map_id,
		&"raid_entry",
		RAID_CLUSTER_RADIUS,
	)
	compiled.enemy_camps = _cluster_markers(
		enemy_img,
		"%s/enemy_camp" % definition.map_id,
		&"enemy_camp",
		ENEMY_CAMP_CLUSTER_RADIUS,
	)
	compiled.landmarks = []
	compiled.stats = {
		"authored": true,
		"raid_entry_count": compiled.raid_entries.size(),
		"enemy_camp_count": compiled.enemy_camps.size(),
		"landmark_count": compiled.landmarks.size(),
	}
	return compiled


static func _load_layer(path: String) -> Image:
	if path.is_empty():
		return null
	var image := Image.load_from_file(ProjectSettings.globalize_path(path))
	if image == null:
		return null
	image.convert(Image.FORMAT_RGBA8)
	return image


static func _cluster_markers(
	image: Image,
	id_prefix: String,
	kind: StringName,
	radius: int,
) -> Array:
	var width := image.get_width()
	var height := image.get_height()
	var claimed: Dictionary = {}
	var results: Array = []
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			if claimed.has(cell):
				continue
			if image.get_pixel(x, y).r8 < MARKER_THRESHOLD:
				continue
			results.append(
				{
					"placement_id": "%s/%d_%d" % [id_prefix, cell.x, cell.y],
					"kind": kind,
					"cell": cell,
					"rotation_deg": 0.0,
				}
			)
			_claim_radius(claimed, cell, radius, width, height)
	return results


static func _claim_radius(claimed: Dictionary, center: Vector2i, radius: int, width: int, height: int) -> void:
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if Vector2i(dx, dy).length() > float(radius) + 0.5:
				continue
			var cell := center + Vector2i(dx, dy)
			if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
				continue
			claimed[cell] = true
