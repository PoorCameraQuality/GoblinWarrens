class_name TreeResource
extends ResourceNode

## Standing tree → physics tip-over → felled log → stump. Wood source for the gather loop.

const _HeightSampler := preload("res://scripts/world/mapgen/height_sampler.gd")

var tree_scene_path: String = ""
var _felled: bool = false
var _fell_progress: float = 0.0
var _stump: Node3D = null
var _fall_pivot: Node3D = null
var _falling: bool = false
var _fall_locked: bool = false
var _fall_angle: float = 0.0
var _fall_angular_vel: float = 0.0
var _fall_target_angle: float = 0.0


func _ready() -> void:
	add_to_group(Defs.GROUP_RESOURCE_NODE)
	set_physics_process(false)
	if remaining <= 0:
		remaining = total_amount
	if not tree_scene_path.is_empty():
		_apply_tree_visual()


func _physics_process(delta: float) -> void:
	if not _falling or _fall_pivot == null:
		return
	var target := _fall_target_angle
	var torque := Constants.TREE_FALL_GRAVITY_TORQUE * cos(_fall_angle)
	_fall_angular_vel += torque * delta
	_fall_angular_vel -= _fall_angular_vel * Constants.TREE_FALL_DAMPING * delta
	_fall_angle += _fall_angular_vel * delta
	if _fall_angle >= target:
		_fall_angle = target
		_fall_angular_vel = 0.0
		_lock_fallen_log()
		return
	if _fall_angle >= target - deg_to_rad(4.0) and absf(_fall_angular_vel) <= Constants.TREE_FALL_SETTLE_SPEED:
		_fall_angle = target
		_fall_angular_vel = 0.0
		_lock_fallen_log()
		return
	_fall_pivot.rotation.x = _fall_angle
	_snap_fall_pivot_to_ground()


func _apply_visual() -> void:
	if not tree_scene_path.is_empty():
		_apply_tree_visual()


func setup_tree(
	cell: Vector2i,
	tree_path: String,
	amount: int,
	world_pos: Vector3,
	rotation_y: float = 0.0,
) -> void:
	tree_scene_path = tree_path
	grid_cell = cell
	resource_kind = Defs.ResourceKind.WOOD
	total_amount = amount
	remaining = amount
	position = world_pos
	rotation.y = rotation_y
	_apply_tree_visual()


func is_felled() -> bool:
	return _felled


func can_gather_now() -> bool:
	return _felled and _fall_locked and remaining > 0


func add_fell_progress(delta: float) -> bool:
	if _felled:
		return true
	_fell_progress += delta
	if _fell_progress >= Constants.TREE_FELL_TIME:
		_apply_felled_state()
		return true
	return false


func fell_progress_ratio() -> float:
	return clampf(_fell_progress / Constants.TREE_FELL_TIME, 0.0, 1.0)


func gather(amount: int) -> int:
	if not can_gather_now():
		return 0
	var taken: int = mini(amount, remaining)
	remaining -= taken
	if remaining <= 0:
		release_reservation(reserved_by)
		_apply_depleted_state()
	return taken


func is_available() -> bool:
	if remaining <= 0:
		return false
	if _felled:
		return _fall_locked
	return true


func _apply_tree_visual() -> void:
	var mesh: CSGBox3D = get_node_or_null("Mesh") as CSGBox3D
	if mesh != null:
		mesh.visible = false
	if tree_scene_path.is_empty():
		tree_scene_path = _VisualCatalog.ENV_TREE
	var scale := _VisualCatalog.env_visual_scale(tree_scene_path)
	_VisualAttacher.try_attach(self, tree_scene_path, ["Mesh"], scale)


func _apply_felled_state() -> void:
	_felled = true
	_spawn_stump()
	_start_fall_physics()


func _start_fall_physics() -> void:
	var art := get_node_or_null("ArtVisual") as Node3D
	if art == null:
		_fall_locked = true
		set_physics_process(false)
		return
	_fall_target_angle = deg_to_rad(Constants.TREE_FALL_TARGET_ANGLE_DEG)
	_fall_angle = 0.0
	_fall_angular_vel = Constants.TREE_FALL_IMPULSE
	_fall_pivot = Node3D.new()
	_fall_pivot.name = "FallPivot"
	add_child(_fall_pivot)
	_fall_pivot.position = art.position
	var fall_yaw := rotation.y + randf_range(-0.45, 0.45)
	_fall_pivot.rotation = Vector3(0.0, fall_yaw, 0.0)
	art.reparent(_fall_pivot)
	art.position = Vector3.ZERO
	art.rotation = Vector3.ZERO
	_falling = true
	_fall_locked = false
	set_physics_process(true)


func _lock_fallen_log() -> void:
	_falling = false
	_fall_locked = true
	set_physics_process(false)
	if _fall_pivot != null:
		_fall_pivot.rotation.x = _fall_target_angle
		_snap_fall_pivot_to_ground()


func _snap_fall_pivot_to_ground() -> void:
	if _fall_pivot == null or Services.map_plan == null:
		return
	var pivot_pos := _fall_pivot.global_position
	var ground_y := _HeightSampler.sample_world(Services.map_plan, pivot_pos.x, pivot_pos.z)
	_fall_pivot.global_position.y = ground_y


func _spawn_stump() -> void:
	if _stump != null:
		return
	var stump_path := _VisualCatalog.stump_for_tree(tree_scene_path)
	if not ResourceLoader.exists(stump_path):
		return
	_stump = _VisualAttacher.spawn_scenery(
		self,
		stump_path,
		Vector3.ZERO,
		_VisualCatalog.env_visual_scale(stump_path),
	)
	if _stump != null:
		_stump.name = "StumpVisual"


func _apply_depleted_state() -> void:
	if _fall_pivot != null:
		_fall_pivot.queue_free()
		_fall_pivot = null
	else:
		var art := get_node_or_null("ArtVisual") as Node3D
		if art != null:
			art.queue_free()
	if Services.movement != null:
		Services.movement.set_solid(grid_cell, false)
