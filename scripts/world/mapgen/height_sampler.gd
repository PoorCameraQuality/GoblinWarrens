class_name HeightSampler
extends RefCounted

## Bilinear height lookup from a MapPlan height field.


static func sample_cell(plan: MapPlan, cell: Vector2i) -> float:
	return sample_world(
		plan,
		(float(cell.x) + 0.5) * Constants.TILE_SIZE,
		(float(cell.y) + 0.5) * Constants.TILE_SIZE,
	)


static func sample_world(plan: MapPlan, world_x: float, world_z: float) -> float:
	if plan.heights.is_empty():
		return 0.0
	var fx := clampf(world_x / Constants.TILE_SIZE, 0.0, float(plan.height_point_width - 1))
	var fz := clampf(world_z / Constants.TILE_SIZE, 0.0, float(plan.height_point_height - 1))
	var x0 := int(floor(fx))
	var z0 := int(floor(fz))
	var x1 := mini(x0 + 1, plan.height_point_width - 1)
	var z1 := mini(z0 + 1, plan.height_point_height - 1)
	var tx := fx - float(x0)
	var tz := fz - float(z0)
	var point_w := plan.height_point_width
	var h00 := plan.heights[z0 * point_w + x0]
	var h10 := plan.heights[z0 * point_w + x1]
	var h01 := plan.heights[z1 * point_w + x0]
	var h11 := plan.heights[z1 * point_w + x1]
	var hx0 := lerpf(h00, h10, tx)
	var hx1 := lerpf(h01, h11, tx)
	return lerpf(hx0, hx1, tz)
