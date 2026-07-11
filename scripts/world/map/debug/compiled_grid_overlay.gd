class_name CompiledGridOverlay
extends MeshInstance3D

## Debug overlay for compiled walkability/buildability grids (dev scenes only).

const WALKABLE_COLOR := Color(0.2, 0.85, 0.35, 0.45)
const BLOCKED_COLOR := Color(0.85, 0.2, 0.2, 0.55)
const BUILDABLE_COLOR := Color(0.25, 0.55, 0.95, 0.45)


func apply_grid(grid: CompiledGridMap) -> void:
	var image := Image.create(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	for y in range(grid.height):
		for x in range(grid.width):
			var cell := Vector2i(x, y)
			var color := BLOCKED_COLOR
			if grid.is_walkable_cell(cell):
				color = WALKABLE_COLOR
			if grid.is_buildable_cell(cell):
				color = BUILDABLE_COLOR
			image.set_pixel(x, y, color)

	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	set_surface_override_material(0, material)

	var mesh := PlaneMesh.new()
	mesh.size = Vector2(
		float(grid.width) * Constants.TILE_SIZE,
		float(grid.height) * Constants.TILE_SIZE,
	)
	mesh.orientation = PlaneMesh.FACE_Y
	self.mesh = mesh
	position = Vector3(
		float(grid.width) * Constants.TILE_SIZE * 0.5,
		0.15,
		float(grid.height) * Constants.TILE_SIZE * 0.5,
	)
