class_name TerrainMeshBuilder
extends RefCounted

## Builds a vertex-colored terrain mesh from height samples and tile classes.


static func build(
	heights: PackedFloat32Array,
	point_w: int,
	point_h: int,
	tile_classes: Array,
) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var tile_w: int = point_w - 1
	var tile_h: int = point_h - 1
	for z in range(tile_h):
		for x in range(tile_w):
			var terrain_class: Defs.TerrainClass = tile_classes[z][x]
			var class_color := Color(float(terrain_class) / 6.0, 0.0, 0.0, 1.0)
			var v00 := _vertex(x, z, heights, point_w)
			var v10 := _vertex(x + 1, z, heights, point_w)
			var v01 := _vertex(x, z + 1, heights, point_w)
			var v11 := _vertex(x + 1, z + 1, heights, point_w)
			_add_triangle(st, v00, v10, v11, class_color)
			_add_triangle(st, v00, v11, v01, class_color)

	return st.commit()


static func _vertex(x: int, z: int, heights: PackedFloat32Array, point_w: int) -> Vector3:
	var y := heights[z * point_w + x]
	return Vector3(float(x) * Constants.TILE_SIZE, y, float(z) * Constants.TILE_SIZE)


static func _add_triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	st.set_normal(_triangle_normal(a, b, c))
	st.add_vertex(a)
	st.set_color(color)
	st.set_normal(_triangle_normal(a, b, c))
	st.add_vertex(b)
	st.set_color(color)
	st.set_normal(_triangle_normal(a, b, c))
	st.add_vertex(c)


static func _triangle_normal(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (b - a).cross(c - a).normalized()
