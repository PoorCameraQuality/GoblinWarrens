class_name GrassFieldRenderer
extends Node3D

## Builds chunked MultiMeshInstance3D grass from a FoliagePlan.
## Visual only — no collision, no shadows cast.

const _FoliagePlan := preload("res://scripts/world/foliage/foliage_plan.gd")
const _FoliagePlanner := preload("res://scripts/world/foliage/foliage_planner.gd")
const _MapConfig := preload("res://data/mapgen/map_config.gd")
const GRASS_SHADER_PATH := "res://game/art/terrain/materials/stylized_grass.gdshader"
const TEX_DIR := "res://game/art/props/nature/goblin_warrens/foliage/"

var _map_plan: MapPlan = null
var _height_grid = null ## CompiledGridMap for authored maps
var _foliage = null ## FoliagePlan
var _config = null ## MapConfig
var _short_mesh: ArrayMesh = null
var _tall_mesh: ArrayMesh = null
var _materials_by_style: Dictionary = {} ## style int -> ShaderMaterial
var _chunk_nodes: Array[MultiMeshInstance3D] = []
var _visible: bool = true
var _active_chunk_count: int = 0
var _instance_total: int = 0


func build(map_plan: MapPlan, foliage) -> void:
	clear()
	_map_plan = map_plan
	_height_grid = null
	_foliage = foliage
	_config = _MapConfig.default_for_demo()
	if foliage == null or foliage.chunks.is_empty():
		return
	_ensure_assets()
	var camp_chunk := Vector2i(
		map_plan.warren_cell.x / int(foliage.chunk_size),
		map_plan.warren_cell.y / int(foliage.chunk_size),
	)
	_build_near_chunk(camp_chunk, foliage)


## Authored map grass near a focus cell (dev / Terrain3D spikes).
func build_authored(height_grid, foliage, focus_cell: Vector2i) -> void:
	clear()
	_map_plan = null
	_height_grid = height_grid
	_foliage = foliage
	_config = _MapConfig.default_for_demo()
	if foliage == null or foliage.chunks.is_empty():
		return
	_ensure_assets()
	var focus_chunk := Vector2i(
		focus_cell.x / int(foliage.chunk_size),
		focus_cell.y / int(foliage.chunk_size),
	)
	_build_near_chunk(focus_chunk, foliage)


func _build_near_chunk(camp_chunk: Vector2i, foliage) -> void:
	var build_radius: int = Constants.FOLIAGE_BUILD_RADIUS_CHUNKS
	var built_instances := 0
	for chunk in foliage.chunks:
		var cid: Vector2i = chunk.get("chunk_id", Vector2i.ZERO)
		if absi(cid.x - camp_chunk.x) > build_radius or absi(cid.y - camp_chunk.y) > build_radius:
			continue
		_spawn_chunk(chunk)
		built_instances += int(chunk.get("short_count", 0)) + int(chunk.get("tall_count", 0))
	_instance_total = built_instances
	if foliage.stats is Dictionary:
		foliage.stats["active_built_chunks"] = _active_chunk_count
		foliage.stats["built_instance_estimate"] = built_instances


func clear() -> void:
	for child in get_children():
		child.queue_free()
	_chunk_nodes.clear()
	_active_chunk_count = 0
	_instance_total = 0


func set_grass_visible(enabled: bool) -> void:
	_visible = enabled
	visible = enabled


func is_grass_visible() -> bool:
	return _visible


func active_chunk_count() -> int:
	return _active_chunk_count


func instance_total() -> int:
	return _instance_total


func suppress_footprint(origin: Vector2i, footprint: Vector2i) -> void:
	## Runtime punch for newly placed buildings — rebuild affected chunk MultiMeshes.
	if _foliage == null or _map_plan == null:
		return
	var cells: Array = []
	for y in range(footprint.y):
		for x in range(footprint.x):
			cells.append(origin + Vector2i(x, y))
	_foliage.suppress_cells(cells)
	var dirty := {}
	var cs: int = int(_foliage.chunk_size)
	for cell in cells:
		var c: Vector2i = cell
		dirty[Vector2i(c.x / cs, c.y / cs)] = true
	for child in get_children():
		if child is MultiMeshInstance3D and child.has_meta("chunk_id"):
			var cid: Vector2i = child.get_meta("chunk_id")
			if dirty.has(cid):
				child.queue_free()
	## Rebuild dirty chunks from plan data.
	for chunk in _foliage.chunks:
		var cid: Vector2i = chunk.get("chunk_id", Vector2i(-1, -1))
		if dirty.has(cid):
			_spawn_chunk(chunk)


func _probe_cell_density(cell: Vector2i) -> Dictionary:
	if _foliage != null and _foliage.density.size() == _foliage.width * _foliage.height:
		return {
			"density": _foliage.sample_density(cell),
			"style": _foliage.sample_style(cell),
		}
	if _map_plan != null:
		return _FoliagePlanner.probe_density(_map_plan, _config, cell, _foliage.blocker_cells)
	return {"density": 0.0, "style": _FoliagePlan.GrassStyle.NONE}


func _sample_world_height(world_x: float, world_z: float) -> float:
	if _height_grid != null:
		var cell := Vector2i(int(floor(world_x)), int(floor(world_z)))
		return _height_grid.sample_height_at_cell(cell)
	if _map_plan != null:
		return HeightSampler.sample_world(_map_plan, world_x, world_z)
	return 0.0


func _ensure_assets() -> void:
	## Textured clump cards (wider than procedural blades — one clump covers more ground).
	if _short_mesh == null:
		_short_mesh = _make_blade_mesh(0.55, 0.38)
	if _tall_mesh == null:
		_tall_mesh = _make_blade_mesh(0.95, 0.48)
	if _materials_by_style.is_empty():
		_materials_by_style[_FoliagePlan.GrassStyle.SHORT_MOSS] = _make_material(
			"grass_clump_lush.png", 0.55, 0.28
		)
		_materials_by_style[_FoliagePlan.GrassStyle.SHADE_SPARSE] = _make_material(
			"grass_clump_mixed.png", 0.55, 0.24
		)
		_materials_by_style[_FoliagePlan.GrassStyle.WET_REED] = _make_material(
			"grass_clump_reed.png", 0.9, 0.32
		)
		_materials_by_style[_FoliagePlan.GrassStyle.DRY_TUFT] = _make_material(
			"grass_clump_dry.png", 0.5, 0.22
		)
		_materials_by_style[_FoliagePlan.GrassStyle.NONE] = _materials_by_style[
			_FoliagePlan.GrassStyle.SHORT_MOSS
		]


func _make_material(filename: String, blade_height: float, sway: float) -> ShaderMaterial:
	var shader := load(GRASS_SHADER_PATH) as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var tex_path := TEX_DIR + filename
	if ResourceLoader.exists(tex_path):
		mat.set_shader_parameter("albedo_tex", load(tex_path))
		mat.set_shader_parameter("use_texture", 1.0)
	else:
		mat.set_shader_parameter("use_texture", 0.0)
	mat.set_shader_parameter("color_bottom", Color(0.16, 0.26, 0.11))
	mat.set_shader_parameter("color_top", Color(0.40, 0.54, 0.20))
	mat.set_shader_parameter("blade_height_m", blade_height)
	mat.set_shader_parameter("sway_amplitude", sway)
	mat.set_shader_parameter("alpha_scissor", 0.32)
	return mat


func _material_for_style(style: int) -> ShaderMaterial:
	if _materials_by_style.has(style):
		return _materials_by_style[style]
	return _materials_by_style[_FoliagePlan.GrassStyle.SHORT_MOSS]


func _spawn_chunk(chunk: Dictionary) -> void:
	var short_count: int = int(chunk.get("short_count", 0))
	var tall_count: int = int(chunk.get("tall_count", 0))
	if short_count <= 0 and tall_count <= 0:
		return
	var origin: Vector2i = chunk.get("origin", Vector2i.ZERO)
	var size: int = int(chunk.get("size", 16))
	var style: int = int(chunk.get("style", _FoliagePlan.GrassStyle.SHORT_MOSS))
	var seed_value: int = int(chunk.get("seed", 1))
	var chunk_id: Vector2i = chunk.get("chunk_id", Vector2i.ZERO)

	if short_count > 0:
		var short_mmi := _make_multimesh_node(
			"GrassShort_%d_%d" % [chunk_id.x, chunk_id.y],
			_short_mesh,
			short_count,
			origin,
			size,
			style,
			seed_value,
			false,
		)
		short_mmi.set_meta("chunk_id", chunk_id)
		add_child(short_mmi)
		_chunk_nodes.append(short_mmi)

	if tall_count > 0:
		var tall_mmi := _make_multimesh_node(
			"GrassTall_%d_%d" % [chunk_id.x, chunk_id.y],
			_tall_mesh,
			tall_count,
			origin,
			size,
			style,
			seed_value + 17,
			true,
		)
		tall_mmi.set_meta("chunk_id", chunk_id)
		add_child(tall_mmi)
		_chunk_nodes.append(tall_mmi)

	_active_chunk_count += 1


func _make_multimesh_node(
	node_name: String,
	mesh: ArrayMesh,
	count: int,
	origin: Vector2i,
	size: int,
	style: int,
	seed_value: int,
	tall: bool,
) -> MultiMeshInstance3D:
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.material_override = _material_for_style(style)
	mmi.visibility_range_begin = 0.0
	mmi.visibility_range_end = Constants.FOLIAGE_FADE_RANGE_M
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	mmi.visibility_range_begin_margin = 4.0
	mmi.visibility_range_end_margin = 12.0

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = count

	var rng := MapRng.new(seed_value)
	var placed := 0
	var attempts := count * 8
	while placed < count and attempts > 0:
		attempts -= 1
		var local := Vector2(
			rng.randf_range(0.0, float(size)),
			rng.randf_range(0.0, float(size)),
		)
		var world_x := float(origin.x) + local.x
		var world_z := float(origin.y) + local.y
		var cell := Vector2i(int(floor(world_x)), int(floor(world_z)))
		if cell.x < 0 or cell.y < 0 or cell.x >= _foliage.width or cell.y >= _foliage.height:
			continue
		if _foliage.suppressed_cells.has(cell):
			continue
		var probe: Dictionary = _probe_cell_density(cell)
		var density: float = float(probe.get("density", 0.0))
		if density <= 0.02:
			continue
		if not rng.roll(clampf(density, 0.05, 1.0)):
			continue
		var y := _sample_world_height(world_x, world_z)
		var yaw := rng.randf_range(0.0, TAU)
		var local_style: int = int(probe.get("style", style))
		var scale_y := _scale_for_style(local_style, tall, rng)
		var scale_xz := scale_y * rng.randf_range(0.85, 1.15)
		var xf := Transform3D.IDENTITY
		xf = xf.scaled(Vector3(scale_xz, scale_y, scale_xz))
		xf = xf.rotated(Vector3.UP, yaw)
		xf.origin = Vector3(world_x, y, world_z)
		mm.set_instance_transform(placed, xf)
		placed += 1

	if placed < count:
		mm.visible_instance_count = placed
	mm.custom_aabb = AABB(
		Vector3(float(origin.x), -2.0, float(origin.y)),
		Vector3(float(size), 4.0, float(size)),
	)
	mmi.multimesh = mm
	return mmi


func _scale_for_style(style: int, tall: bool, rng: MapRng) -> float:
	var base := 1.0
	match style:
		_FoliagePlan.GrassStyle.SHORT_MOSS:
			base = 0.85 if not tall else 1.15
		_FoliagePlan.GrassStyle.SHADE_SPARSE:
			base = 0.7 if not tall else 0.95
		_FoliagePlan.GrassStyle.WET_REED:
			base = 1.05 if not tall else 1.45
		_FoliagePlan.GrassStyle.DRY_TUFT:
			base = 0.65 if not tall else 0.8
		_:
			base = 0.8
	return base * rng.randf_range(0.9, 1.15)


func _make_blade_mesh(height: float, half_width: float) -> ArrayMesh:
	## Two crossed vertical quads (alpha-tested). Pivot at ground.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	_append_quad(verts, normals, uvs, indices, height, half_width, 0.0)
	_append_quad(verts, normals, uvs, indices, height, half_width, PI * 0.5)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _append_quad(
	verts: PackedVector3Array,
	normals: PackedVector3Array,
	uvs: PackedVector2Array,
	indices: PackedInt32Array,
	height: float,
	half_width: float,
	yaw: float,
) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var bl := basis * Vector3(-half_width, 0.0, 0.0)
	var br := basis * Vector3(half_width, 0.0, 0.0)
	var tl := basis * Vector3(-half_width, height, 0.0)
	var tr := basis * Vector3(half_width, height, 0.0)
	var n := (basis * Vector3(0.0, 0.0, 1.0)).normalized()
	var base := verts.size()
	verts.append(bl)
	verts.append(br)
	verts.append(tr)
	verts.append(tl)
	for _i in range(4):
		normals.append(n)
	uvs.append(Vector2(0.0, 1.0))
	uvs.append(Vector2(1.0, 1.0))
	uvs.append(Vector2(1.0, 0.0))
	uvs.append(Vector2(0.0, 0.0))
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)
	indices.append(base)
	indices.append(base + 2)
	indices.append(base + 3)
