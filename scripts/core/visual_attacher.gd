class_name VisualAttacher
extends RefCounted

## Instantiates production wrapper scenes; hides CSG fallbacks when art loads.


static func try_attach(
	parent: Node3D,
	wrapper_path: String,
	hide_node_paths: Array[String] = [],
	scale: Vector3 = Vector3.ONE,
	position: Vector3 = Vector3.ZERO
) -> Node3D:
	if wrapper_path.is_empty():
		return null
	if not ResourceLoader.exists(wrapper_path):
		Log.warn("VisualAttacher: missing wrapper %s" % wrapper_path, "visual_attacher")
		return null
	var packed: PackedScene = load(wrapper_path) as PackedScene
	if packed == null:
		Log.warn("VisualAttacher: failed to load %s" % wrapper_path, "visual_attacher")
		return null
	var existing := parent.get_node_or_null("ArtVisual") as Node3D
	if existing != null:
		existing.queue_free()
	var instance: Node3D = packed.instantiate() as Node3D
	if instance == null:
		return null
	instance.name = "ArtVisual"
	instance.scale = scale
	instance.position = position
	parent.add_child(instance)
	_normalize_ground_contact(instance)
	for path in hide_node_paths:
		var node := parent.get_node_or_null(path)
		if node == null and parent.get_parent() != null:
			node = parent.get_parent().get_node_or_null(path)
		if node is Node3D:
			(node as Node3D).visible = false
		elif node is CSGShape3D:
			(node as CSGShape3D).visible = false
	return instance


static func spawn_scenery(
	parent: Node3D,
	wrapper_path: String,
	world_pos: Vector3,
	scale: Vector3 = Vector3.ONE,
) -> Node3D:
	if wrapper_path.is_empty() or not ResourceLoader.exists(wrapper_path):
		return null
	var packed: PackedScene = load(wrapper_path) as PackedScene
	if packed == null:
		return null
	var instance: Node3D = packed.instantiate() as Node3D
	if instance == null:
		return null
	instance.scale = scale
	instance.position = world_pos
	parent.add_child(instance)
	_normalize_ground_contact(instance)
	return instance


static func attach_to_container(
	root: Node,
	container_path: String,
	wrapper_path: String,
	hide_node_paths: Array[String] = [],
	scale: Vector3 = Vector3.ONE,
	position: Vector3 = Vector3.ZERO
) -> Node3D:
	var container := root.get_node_or_null(container_path) as Node3D
	if container == null:
		return try_attach(root as Node3D, wrapper_path, hide_node_paths, scale, position)
	return try_attach(container, wrapper_path, hide_node_paths, scale, position)


static func tint_meshes(root: Node, albedo: Color) -> void:
	if root is MeshInstance3D:
		var mesh := root as MeshInstance3D
		var mat := StandardMaterial3D.new()
		mat.albedo_color = albedo
		mesh.material_override = mat
	for child in root.get_children():
		tint_meshes(child, albedo)


## Lift model up so its AABB base sits at parent.y (base at ground contact).
## Meshy exports center models at origin (AABB.position.y ~= -half_height);
## Kaykit/Quaternius wrappers already have their base at y=0 so this becomes a no-op.
static func _normalize_ground_contact(instance: Node3D) -> void:
	var aabb := _compute_visual_aabb(instance)
	if aabb.size == Vector3.ZERO:
		return
	if aabb.position.y < -0.01:
		instance.position.y += -aabb.position.y


static func _compute_visual_aabb(root: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi: MeshInstance3D = n
			var mesh_aabb: AABB = mi.get_aabb()
			if first:
				out = mesh_aabb
				first = false
			else:
				out = out.merge(mesh_aabb)
		for c in n.get_children():
			stack.push_back(c)
	return out
