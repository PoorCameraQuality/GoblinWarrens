extends MeshInstance3D

## Debug overlay for runtime walkability or procgen buildability (Phase 9).

const WALKABLE_COLOR := Color(0.2, 0.85, 0.35, 0.42)
const BLOCKED_COLOR := Color(0.85, 0.2, 0.2, 0.5)
const BUILDABLE_COLOR := Color(0.25, 0.55, 0.95, 0.42)
const NON_BUILDABLE_COLOR := Color(0.35, 0.35, 0.35, 0.25)

const _TerrainClassifier := preload("res://scripts/world/mapgen/terrain_classifier.gd")


func apply_walkability(movement: MovementAdapter, y_offset: float = 0.12) -> void:
	if movement == null:
		return
	var width := movement.grid_width()
	var height := movement.grid_height()
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	for y in range(height):
		for x in range(width):
			var cell := Vector2i(x, y)
			var color := WALKABLE_COLOR if movement.is_walkable(cell) else BLOCKED_COLOR
			image.set_pixel(x, y, color)
	_apply_image(image, width, height, y_offset)


func apply_buildability(plan: MapPlan, y_offset: float = 0.12) -> void:
	if plan == null:
		return
	var image := Image.create(plan.width, plan.height, false, Image.FORMAT_RGBA8)
	for y in range(plan.height):
		for x in range(plan.width):
			var terrain_class: Defs.TerrainClass = plan.tile_classes[y][x]
			var color := BUILDABLE_COLOR if _TerrainClassifier.is_buildable(terrain_class) else NON_BUILDABLE_COLOR
			image.set_pixel(x, y, color)
	_apply_image(image, plan.width, plan.height, y_offset)


func _apply_image(image: Image, width: int, height: int, y_offset: float) -> void:
	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	set_surface_override_material(0, material)

	var plane := PlaneMesh.new()
	plane.size = Vector2(float(width) * Constants.TILE_SIZE, float(height) * Constants.TILE_SIZE)
	plane.orientation = PlaneMesh.FACE_Y
	mesh = plane
	position = Vector3(
		float(width) * Constants.TILE_SIZE * 0.5,
		y_offset,
		float(height) * Constants.TILE_SIZE * 0.5,
	)
