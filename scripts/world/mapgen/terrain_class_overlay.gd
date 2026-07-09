class_name TerrainClassOverlayBuilder
extends RefCounted

const _SHADER := preload("res://game/art/terrain/materials/terrain_class_overlay.gdshader")


static func build() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER
	_set_color(mat, "color_mud_clearing", Defs.TerrainClass.MUD_CLEARING)
	_set_color(mat, "color_moss", Defs.TerrainClass.MOSS)
	_set_color(mat, "color_forest_floor", Defs.TerrainClass.FOREST_FLOOR)
	_set_color(mat, "color_rocky_slope", Defs.TerrainClass.ROCKY_SLOPE)
	_set_color(mat, "color_mud_mossy", Defs.TerrainClass.MUD_MOSSY)
	_set_color(mat, "color_cliff", Defs.TerrainClass.CLIFF)
	_set_color(mat, "color_warren_ground", Defs.TerrainClass.WARREN_GROUND)
	return mat


static func _set_color(mat: ShaderMaterial, param: String, terrain_class: Defs.TerrainClass) -> void:
	var base := TerrainClassifier.class_color(terrain_class)
	# Boost saturation/value so classes read clearly from RTS camera height.
	mat.set_shader_parameter(param, Color(
		clampf(base.r * 1.45, 0.0, 1.0),
		clampf(base.g * 1.45, 0.0, 1.0),
		clampf(base.b * 1.45, 0.0, 1.0),
	))
