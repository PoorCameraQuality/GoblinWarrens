class_name TerrainTransitionOverlayBuilder
extends RefCounted

const _SHADER := preload("res://game/art/terrain/materials/terrain_transition_overlay.gdshader")


static func build(plan: MapPlan) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = _SHADER
	if plan != null and plan.blend_control != null:
		mat.set_shader_parameter("blend_control", plan.blend_control)
		mat.set_shader_parameter("blend_enabled", true)
		mat.set_shader_parameter(
			"map_size_m",
			Vector2(float(plan.width) * Constants.TILE_SIZE, float(plan.height) * Constants.TILE_SIZE),
		)
	else:
		mat.set_shader_parameter("blend_enabled", false)
	return mat
