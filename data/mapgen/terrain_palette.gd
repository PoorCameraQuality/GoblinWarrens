class_name TerrainPalette
extends RefCounted

## Terrain texture paths per class — see docs/terrain-texture-brief.md.

const _ROOT := "res://game/art/terrain/goblin_warrens/"

static var _warned_missing_macro: Dictionary = {}


static func resolve_primary_texture(class_id: Defs.TerrainClass) -> String:
	var macro_path := macro_texture(class_id)
	if ResourceLoader.exists(macro_path):
		return macro_path
	var legacy_path := legacy_texture(class_id)
	if not _warned_missing_macro.has(class_id):
		_warned_missing_macro[class_id] = true
		push_warning(
			"Macro terrain texture missing for class %d (%s); using legacy %s"
			% [int(class_id), macro_path, legacy_path]
		)
	return legacy_path


static func primary_texture(class_id: Defs.TerrainClass) -> String:
	return resolve_primary_texture(class_id)


static func macro_texture(class_id: Defs.TerrainClass) -> String:
	match class_id:
		Defs.TerrainClass.MUD_CLEARING:
			return _ROOT + "dirt_packed_macro.png"
		Defs.TerrainClass.MOSS:
			return _ROOT + "forest_floor_moss_macro.png"
		Defs.TerrainClass.FOREST_FLOOR:
			return _ROOT + "forest_floor_litter_macro.png"
		Defs.TerrainClass.ROCKY_SLOPE:
			return _ROOT + "rocky_slope_macro.png"
		Defs.TerrainClass.MUD_MOSSY:
			return _ROOT + "mud_mossy_macro.png"
		Defs.TerrainClass.CLIFF:
			return _ROOT + "cliff_face_macro.png"
		Defs.TerrainClass.WARREN_GROUND:
			return _ROOT + "warren_ground_macro.png"
		_:
			return _ROOT + "dirt_packed_macro.png"


static func legacy_texture(class_id: Defs.TerrainClass) -> String:
	match class_id:
		Defs.TerrainClass.MUD_CLEARING:
			return _ROOT + "dirt_packed.png"
		Defs.TerrainClass.MOSS:
			return _ROOT + "forest_floor_moss.png"
		Defs.TerrainClass.FOREST_FLOOR:
			return _ROOT + "forest_floor_roots_heavy.png"
		Defs.TerrainClass.ROCKY_SLOPE:
			return _ROOT + "forest_floor_rocky.png"
		Defs.TerrainClass.MUD_MOSSY:
			return _ROOT + "mud_mossy.png"
		Defs.TerrainClass.CLIFF:
			return _ROOT + "mud_bedrock.png"
		Defs.TerrainClass.WARREN_GROUND:
			return _ROOT + "mud_root_lattice.png"
		_:
			return _ROOT + "dirt_packed.png"


static func all_macro_textures_present() -> bool:
	for class_id in range(7):
		var terrain_class: Defs.TerrainClass = class_id as Defs.TerrainClass
		if not ResourceLoader.exists(macro_texture(terrain_class)):
			return false
	return true


static func preferred_uv_scale() -> float:
	if all_macro_textures_present():
		return Constants.TERRAIN_UV_SCALE_MACRO
	return Constants.TERRAIN_UV_SCALE_LEGACY


static func shader_param_name(class_id: Defs.TerrainClass) -> String:
	match class_id:
		Defs.TerrainClass.MUD_CLEARING:
			return "tex_mud_clearing"
		Defs.TerrainClass.MOSS:
			return "tex_moss"
		Defs.TerrainClass.FOREST_FLOOR:
			return "tex_forest_floor"
		Defs.TerrainClass.ROCKY_SLOPE:
			return "tex_rocky_slope"
		Defs.TerrainClass.MUD_MOSSY:
			return "tex_mud_mossy"
		Defs.TerrainClass.CLIFF:
			return "tex_cliff"
		Defs.TerrainClass.WARREN_GROUND:
			return "tex_warren_ground"
		_:
			return "tex_mud_clearing"
