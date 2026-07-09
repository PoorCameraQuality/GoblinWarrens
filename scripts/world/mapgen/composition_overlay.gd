class_name CompositionOverlayBuilder
extends RefCounted

## Builds a debug Node3D with colored quads for raid lane / approach / pockets.


static func build_node(plan: MapPlan) -> Node3D:
	var root := Node3D.new()
	root.name = "CompositionOverlay"
	if plan == null:
		return root
	_add_colored_cells(root, plan, plan.main_raid_path_cells, Color(0.9, 0.5, 0.15, 0.8), 0.14)
	var approach_only: Dictionary = {}
	for key in plan.approach_corridor_cells.keys():
		if not plan.main_raid_path_cells.has(key):
			approach_only[key] = true
	_add_colored_cells(root, plan, approach_only, Color(0.55, 0.38, 0.2, 0.5), 0.1)
	_add_colored_cells(root, plan, plan.resource_pocket_cells, Color(0.25, 0.85, 0.4, 0.75), 0.22)
	return root


static func _add_colored_cells(
	root: Node3D,
	plan: MapPlan,
	cells: Dictionary,
	color: Color,
	y_lift: float,
) -> void:
	if cells.is_empty():
		return
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	## Cap debug quads so overlay stays usable on 350 maps.
	var count := 0
	var max_quads := 2500
	for key in cells.keys():
		if count >= max_quads:
			break
		count += 1
		var cell: Vector2i = key
		var mi := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(Constants.TILE_SIZE * 0.9, 0.06, Constants.TILE_SIZE * 0.9)
		mi.mesh = box
		mi.material_override = mat
		var h := HeightSampler.sample_cell(plan, cell)
		mi.position = Vector3(
			(float(cell.x) + 0.5) * Constants.TILE_SIZE,
			h + y_lift,
			(float(cell.y) + 0.5) * Constants.TILE_SIZE,
		)
		root.add_child(mi)
