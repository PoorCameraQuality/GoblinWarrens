class_name MapDefinitionFactory
extends RefCounted

## Builds GoblinMapDefinition from manifest.json + import_report.json.

const _DEFAULT_BIOME_NAMES := {
	0: "Void",
	1: "Deep Wetland",
	2: "Temperate Forest",
	3: "Wetland",
	4: "Meadow",
	5: "Pine Foothills",
	6: "Road",
	7: "Rock",
}


static func load_from_map_root(
	map_root: String,
	target_size: Vector2i = Vector2i(Constants.GRID_WIDTH, Constants.GRID_HEIGHT),
) -> Variant:
	var manifest_path := map_root.path_join("manifest.json")
	if not FileAccess.file_exists(manifest_path):
		push_error("MapDefinitionFactory: missing manifest at %s" % manifest_path)
		return null

	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if manifest.is_empty():
		push_error("MapDefinitionFactory: invalid manifest at %s" % manifest_path)
		return null

	var report := _load_import_report(map_root, target_size)
	if report.is_empty() or not bool(report.get("ok", false)):
		push_error("MapDefinitionFactory: import report missing or failed for %s" % map_root)
		return null

	var def = load("res://scripts/world/map/resources/goblin_map_definition.gd").new()
	def.map_root = map_root
	def.map_id = str(manifest.get("map_id", ""))
	def.display_name = str(manifest.get("display_name", ""))
	def.map_version = int(manifest.get("version", 1))
	def.map_seed = int(manifest.get("map_seed", manifest.get("seed", 0)))
	def.grid_width = target_size.x
	def.grid_height = target_size.y
	def.source_dir = str(report.get("source_dir", map_root.path_join("source")))
	def.baked_dir = str(report.get("baked_dir", ""))
	def.terrain3d_data_dir = map_root.path_join("terrain3d_data")
	def.layer_paths = report.get("baked_files", {}).duplicate(true)

	var files: Dictionary = manifest.get("files", {})
	def.terrain_heightmap_path = def.get_layer_path("heightmap")
	if def.terrain_heightmap_path.is_empty():
		var height_file := str(files.get("heightmap", ""))
		if not height_file.is_empty():
			def.terrain_heightmap_path = def.baked_dir.path_join(height_file)

	def.validation_profile = _validation_from_manifest(manifest)
	def.biomes = _biomes_from_palette(manifest.get("biome_palette", {}))
	def.seed_foliage = _seed_channel(def.map_id, "foliage")
	def.seed_harvestable = _seed_channel(def.map_id, "harvestable")
	def.seed_resource = _seed_channel(def.map_id, "resource")
	def.seed_ambient = _seed_channel(def.map_id, "ambient")
	def.seed_enemy = _seed_channel(def.map_id, "enemy")
	def.seed_clutter = _seed_channel(def.map_id, "clutter")
	return def


static func create_baked_map_data(map_root: String) -> Variant:
	var def = load_from_map_root(map_root)
	if def == null:
		return null
	var baked = load("res://scripts/world/map/resources/baked_map_data.gd").new()
	baked.definition = def
	baked.compiled_grid_fingerprint = _read_phase2_fingerprint(map_root)
	return baked


static func _load_import_report(map_root: String, target_size: Vector2i) -> Dictionary:
	var report_path := map_root.path_join("import_report.json")
	if FileAccess.file_exists(report_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(report_path))
		if parsed is Dictionary and bool(parsed.get("ok", false)):
			return parsed

	var importer := load("res://scripts/world/map/map_semantic_importer.gd")
	var imported: Dictionary = importer.import_map(map_root, target_size)
	return imported


static func _validation_from_manifest(manifest: Dictionary) -> Variant:
	var profile = load("res://scripts/world/map/resources/map_validation_profile.gd").new()
	var rules: Dictionary = manifest.get("gameplay_rules", {})
	profile.swamp_speed_multiplier = float(rules.get("swamp_speed_multiplier", 0.1))
	profile.mountains_impassable = bool(rules.get("mountains_impassable", true))
	profile.lane_count = int(rules.get("lane_count", 0))
	return profile


static func _biomes_from_palette(palette: Dictionary) -> Array:
	var out: Array = []
	for hex: String in palette.keys():
		var biome_id := int(palette[hex])
		var BiomeProfileScript = load("res://scripts/world/map/resources/biome_profile.gd")
		var entry = BiomeProfileScript.new()
		entry.biome_id = biome_id
		entry.palette_color = Color.from_string(hex, Color.MAGENTA)
		entry.display_name = str(_DEFAULT_BIOME_NAMES.get(biome_id, "Biome %d" % biome_id))
		out.append(entry)
	out.sort_custom(func(a, b) -> bool: return a.biome_id < b.biome_id)
	return out


static func _seed_channel(map_id: String, channel: String) -> int:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update((map_id + ":" + channel).to_utf8_buffer())
	return int(ctx.finish().hex_encode().substr(0, 8).hex_to_int())


static func _read_phase2_fingerprint(map_root: String) -> String:
	var artifact_path := map_root.path_join("phase2_regression_artifact.json")
	if not FileAccess.file_exists(artifact_path):
		return ""
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(artifact_path))
	if parsed is Dictionary:
		return str(parsed.get("fingerprint", ""))
	return ""
