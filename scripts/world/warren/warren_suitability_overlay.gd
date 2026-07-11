class_name WarrenSuitabilityOverlay
extends MeshInstance3D

## Heat-map overlay for Warren placement suitability (dev scenes only).

const _Controller := preload("res://scripts/world/warren/warren_placement_controller.gd")

const COLOR_INVALID := Color(0.35, 0.05, 0.05, 0.65)
const COLOR_POOR := Color(0.85, 0.35, 0.1, 0.55)
const COLOR_ACCEPTABLE := Color(0.95, 0.85, 0.15, 0.55)
const COLOR_GOOD := Color(0.15, 0.85, 0.25, 0.55)
const COLOR_RICH := Color(0.1, 0.85, 0.85, 0.6)
const COLOR_DANGEROUS := Color(0.9, 0.1, 0.55, 0.65)
const COLOR_DEFENSIBLE := Color(0.2, 0.45, 0.95, 0.55)
const COLOR_EXPOSED := Color(0.95, 0.55, 0.1, 0.6)
const COLOR_CANDIDATE := Color(1.0, 1.0, 1.0, 0.95)


func apply_context(context: Dictionary, candidates: Array = [], stride: int = 3) -> void:
	var grid = context.get("grid")
	if grid == null:
		return
	var image := Image.create(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var footprint := Vector2i(2, 2)
	for y in range(0, grid.height, stride):
		for x in range(0, grid.width, stride):
			var origin := Vector2i(x, y)
			var report: Dictionary = _Controller.evaluate(context, origin, footprint)
			var color := _color_for_report(report)
			for dy in range(mini(stride, grid.height - y)):
				for dx in range(mini(stride, grid.width - x)):
					image.set_pixel(x + dx, y + dy, color)
	for report in candidates:
		if report is Dictionary:
			var origin: Vector2i = report.get("origin", Vector2i(-1, -1))
			for dy in range(footprint.y):
				for dx in range(footprint.x):
					var cell := origin + Vector2i(dx, dy)
					if grid.is_in_bounds(cell):
						image.set_pixel(cell.x, cell.y, COLOR_CANDIDATE)
	_apply_image(grid, image)


func highlight_origin(grid, origin: Vector2i, footprint: Vector2i = Vector2i(2, 2)) -> void:
	if grid == null:
		return
	var image := Image.create(grid.width, grid.height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for dy in range(footprint.y):
		for dx in range(footprint.x):
			var cell := origin + Vector2i(dx, dy)
			if grid.is_in_bounds(cell):
				image.set_pixel(cell.x, cell.y, COLOR_CANDIDATE)
	_apply_image(grid, image)


func _color_for_report(report: Dictionary) -> Color:
	if not bool(report.get("valid", false)):
		return COLOR_INVALID
	match int(report.get("label", _Controller.SuitabilityLabel.POOR)):
		_Controller.SuitabilityLabel.GOOD:
			return COLOR_GOOD
		_Controller.SuitabilityLabel.ACCEPTABLE:
			return COLOR_ACCEPTABLE
		_Controller.SuitabilityLabel.RICH:
			return COLOR_RICH
		_Controller.SuitabilityLabel.DANGEROUS:
			return COLOR_DANGEROUS
		_Controller.SuitabilityLabel.DEFENSIBLE:
			return COLOR_DEFENSIBLE
		_Controller.SuitabilityLabel.EXPOSED:
			return COLOR_EXPOSED
		_:
			return COLOR_POOR


func _apply_image(grid, image: Image) -> void:
	var texture := ImageTexture.create_from_image(image)
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	set_surface_override_material(0, material)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(float(grid.width) * Constants.TILE_SIZE, float(grid.height) * Constants.TILE_SIZE)
	mesh.orientation = PlaneMesh.FACE_Y
	self.mesh = mesh
	position = Vector3(
		float(grid.width) * Constants.TILE_SIZE * 0.5,
		0.2,
		float(grid.height) * Constants.TILE_SIZE * 0.5,
	)
