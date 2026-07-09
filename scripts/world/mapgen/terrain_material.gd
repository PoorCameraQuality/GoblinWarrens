class_name TerrainMaterialBuilder
extends RefCounted

const _SHADER := preload("res://game/art/terrain/materials/terrain_blend.gdshader")


static func build(plan: MapPlan = null) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER
	var bound := 0
	for class_id in range(7):
		var terrain_class: Defs.TerrainClass = class_id as Defs.TerrainClass
		var tex_path := TerrainPalette.resolve_primary_texture(terrain_class)
		var param := TerrainPalette.shader_param_name(terrain_class)
		if not ResourceLoader.exists(tex_path):
			Log.error("Terrain texture missing for class %d: %s" % [class_id, tex_path], "terrain")
			continue
		var tex: Texture2D = load(tex_path) as Texture2D
		if tex == null:
			Log.error("Terrain texture failed to load for class %d: %s" % [class_id, tex_path], "terrain")
			continue
		mat.set_shader_parameter(param, tex)
		bound += 1
	var uv := TerrainPalette.preferred_uv_scale()
	mat.set_shader_parameter("uv_scale", uv)
	mat.set_shader_parameter("roughness", 0.92)
	var blend_enabled := plan != null and plan.blend_control != null
	mat.set_shader_parameter("blend_enabled", blend_enabled)
	if blend_enabled:
		mat.set_shader_parameter("blend_control", plan.blend_control)
		mat.set_shader_parameter(
			"map_size_m",
			Vector2(float(plan.width) * Constants.TILE_SIZE, float(plan.height) * Constants.TILE_SIZE),
		)
		mat.set_shader_parameter("blend_noise_strength", 0.15)
		mat.set_shader_parameter("blend_noise_scale", 0.08)
	if OS.is_debug_build():
		Log.info(
			"TerrainMaterial bound %d/7 textures uv_scale=%.3f macro_mode=%s blend=%s"
			% [bound, uv, TerrainPalette.all_macro_textures_present(), blend_enabled],
			"terrain",
		)
	return mat
