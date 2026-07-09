class_name EnemyUnit
extends Node3D

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")

## Simple melee enemy for beasts, scouts, and raiders.

@export var enemy_kind: Defs.EnemyKind = Defs.EnemyKind.BEAST

var grid_cell: Vector2i = Vector2i.ZERO
var hp: int = 20
var max_hp: int = 20
var attack_damage: int = 5
var actor_id: String = ""

var _movement: MovementAdapter = null
var _path: Array[Vector2i] = []
var _path_index: int = 0
var _move_progress: float = 0.0
var _attack_timer: float = 0.0
var _target: Node3D = null
var _scout_timer: float = 0.0
var _retreating: bool = false
var _colony: GoblinWarrenColony = null


func setup(
	kind: Defs.EnemyKind,
	cell: Vector2i,
	movement: MovementAdapter,
	colony: GoblinWarrenColony
) -> void:
	enemy_kind = kind
	grid_cell = cell
	_movement = movement
	_colony = colony
	actor_id = "enemy_%s_%d" % [kind, Time.get_ticks_msec()]
	_apply_kind_stats()
	_sync_transform()
	_ensure_mesh()


func _ready() -> void:
	add_to_group(Defs.GROUP_ENEMY)


func tick_combat(delta: float) -> void:
	if hp <= 0:
		return
	if enemy_kind == Defs.EnemyKind.SCOUT and not _retreating:
		_tick_scout(delta)
		return
	if _colony != null:
		var warren := _colony.get_warren()
		if warren != null and is_instance_valid(warren) and warren.is_destroyed():
			queue_free()
			return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_target = _find_target()
	if _target == null:
		return
	var target_cell: Vector2i = _target_cell(_target)
	var dist: float = global_position.distance_to(_target.global_position)
	if dist <= Constants.ENEMY_ATTACK_RANGE:
		if _attack_timer <= 0.0:
			_perform_attack(_target)
			_attack_timer = Constants.ENEMY_ATTACK_COOLDOWN
		return
	if _path.is_empty() or _path_index >= _path.size():
		_move_to(target_cell)
	tick_movement(delta)


func tick_movement(delta: float) -> void:
	if _path.is_empty() or _path_index >= _path.size():
		return
	var next_cell: Vector2i = _path[_path_index]
	if next_cell == grid_cell:
		_path_index += 1
		_move_progress = 0.0
		return
	_move_progress += delta * Constants.GOBLIN_MOVE_SPEED
	if _move_progress >= 1.0:
		grid_cell = next_cell
		_path_index += 1
		_move_progress = 0.0
		_sync_transform()
		return
	var from: Vector3 = _movement.grid_to_world(grid_cell)
	var to: Vector3 = _movement.grid_to_world(next_cell)
	global_position = from.lerp(to, _move_progress)


func take_damage(amount: int, source: Node = null) -> void:
	hp = maxi(0, hp - amount)
	if hp <= 0:
		if _colony != null:
			_colony.on_enemy_killed(self, source)
		queue_free()


func _tick_scout(delta: float) -> void:
	_scout_timer += delta
	if _scout_timer < Constants.SCOUT_OBSERVE_TIME:
		tick_movement(delta)
		return
	_retreating = true
	var edge := Vector2i(0, grid_cell.y)
	_move_to(edge)
	tick_movement(delta)
	if grid_cell.x <= 0:
		queue_free()


func _perform_attack(target: Node3D) -> void:
	if target.has_method("take_damage"):
		target.call("take_damage", attack_damage, self)


func _find_target() -> Node3D:
	var warren := _colony.get_warren() if _colony != null else null
	if warren != null and not warren.is_destroyed():
		return warren
	var best: Node3D = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_GOBLIN):
		if not node is Goblin:
			continue
		var goblin := node as Goblin
		if not goblin.is_alive():
			continue
		var dist: float = global_position.distance_squared_to(goblin.global_position)
		if dist < best_dist:
			best_dist = dist
			best = goblin
	for node in get_tree().get_nodes_in_group(Defs.GROUP_FOBLIN):
		if not node is Goblin:
			continue
		var foblin := node as Goblin
		if not foblin.is_alive():
			continue
		var dist: float = global_position.distance_squared_to(foblin.global_position)
		if dist < best_dist:
			best_dist = dist
			best = foblin
	return best


func _target_cell(target: Node3D) -> Vector2i:
	if target is Building:
		return (target as Building).grid_cell
	if target.has_method("get_grid_cell"):
		return target.call("get_grid_cell")
	if target is Goblin:
		return (target as Goblin).grid_cell
	return grid_cell


func _move_to(target_cell: Vector2i) -> void:
	var raw: Array[Vector2i] = _movement.find_path(grid_cell, target_cell)
	_path = []
	_path_index = 0
	_move_progress = 0.0
	if raw.size() <= 1:
		return
	for i in range(1, raw.size()):
		_path.append(raw[i])


func _apply_kind_stats() -> void:
	match enemy_kind:
		Defs.EnemyKind.BEAST:
			max_hp = Constants.BEAST_HP
			attack_damage = Constants.BEAST_DAMAGE
		Defs.EnemyKind.SCOUT:
			max_hp = Constants.SCOUT_HP
			attack_damage = Constants.SCOUT_DAMAGE
		Defs.EnemyKind.MILITIA:
			max_hp = Constants.MILITIA_HP
			attack_damage = Constants.MILITIA_DAMAGE
	hp = max_hp


func _sync_transform() -> void:
	global_position = _movement.grid_to_world(grid_cell)


func _ensure_mesh() -> void:
	if get_node_or_null("ArtVisual") != null:
		return
	var path: String = _VisualCatalog.enemy_wrapper(enemy_kind)
	var visual_scale := _VisualCatalog.enemy_visual_scale(enemy_kind)
	var art := _VisualAttacher.try_attach(self, path, ["Mesh"], visual_scale)
	if art != null:
		if enemy_kind == Defs.EnemyKind.MILITIA:
			_VisualAttacher.tint_meshes(art, Color(0.55, 0.58, 0.72))
		_add_threat_ring()
		return
	if get_node_or_null("Mesh") != null:
		return
	var mesh := CSGBox3D.new()
	mesh.name = "Mesh"
	mesh.position = Vector3(0.0, 0.45, 0.0)
	var mat := StandardMaterial3D.new()
	var csg_scale: float = visual_scale.x
	match enemy_kind:
		Defs.EnemyKind.BEAST:
			mat.albedo_color = Color(0.45, 0.25, 0.15)
			mesh.size = Vector3(0.9, 0.8, 1.2) * csg_scale
		Defs.EnemyKind.SCOUT:
			mat.albedo_color = Color(0.7, 0.65, 0.5)
			mesh.size = Vector3(0.55, 0.9, 0.55) * csg_scale
		Defs.EnemyKind.MILITIA:
			mat.albedo_color = Color(0.55, 0.55, 0.75)
			mesh.size = Vector3(0.75, 1.15, 0.75) * csg_scale
			mat.emission_enabled = true
			mat.emission = Color(0.35, 0.35, 0.55)
	mesh.material = mat
	add_child(mesh)
	_add_threat_ring()


func _add_threat_ring() -> void:
	if get_node_or_null("ThreatRing") != null:
		return
	var ring_scale: float = Constants.ENEMY_VISUAL_SCALE
	var ring := CSGTorus3D.new()
	ring.name = "ThreatRing"
	ring.position = Vector3(0.0, 0.08, 0.0)
	var major: float = 0.85 * ring_scale
	var tube: float = 0.07
	ring.inner_radius = major - tube
	ring.outer_radius = major + tube
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.15, 0.1)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.1, 0.05)
	ring.material = ring_mat
	add_child(ring)
