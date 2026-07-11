class_name Goblin
extends Node3D

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")

## Goblin worker: gather → haul → storehouse, or hammer construction sites.
## Player RTS commands override auto job assignment until the command finishes.

@export var actor_id: String = ""
@export var display_name: String = "Goblin"
@export var hunger: float = 20.0
@export var energy: float = 100.0

var is_foblin_unit: bool = false
var is_hobgoblin_warrior: bool = false
var is_hobgoblin_mage: bool = false
var grid_cell: Vector2i = Vector2i.ZERO
var job_kind: Defs.JobKind = Defs.JobKind.IDLE
var worker_phase: Defs.WorkerPhase = Defs.WorkerPhase.IDLE

var max_hp: int = Constants.GOBLIN_MAX_HP
var hp: int = Constants.GOBLIN_MAX_HP
var attack_damage: int = Constants.GOBLIN_ATTACK_DAMAGE
var is_militia: bool = false
var gather_multiplier: float = 1.0
var build_multiplier: float = 1.0
var crowding_work_multiplier: float = 1.0 ## colony population bracket; set by colony each tick
var starvation_level: float = 0.0
var damage_buff_timer: float = 0.0

var carried_kind: Defs.ResourceKind = Defs.ResourceKind.WOOD
var carried_amount: int = 0

var _path: Array[Vector2i] = []
var _path_index: int = 0
var _move_progress: float = 0.0
var _work_timer: float = 0.0
var _attack_timer: float = 0.0
var _movement: MovementAdapter = null
var _gather_target: ResourceNode = null
var _build_target: ConstructionSite = null
var _forager_target: ForagerPost = null
var _shrine_target: ShrineBuilding = null
var _storehouse: Storehouse = null
var _player_owned: bool = false
var _gather_chain: bool = false
var _chain_kind: Defs.ResourceKind = Defs.ResourceKind.WOOD
var _colony: GoblinWarrenColony = null
var _alive: bool = true


func setup(start_cell: Vector2i, movement: MovementAdapter, colony: GoblinWarrenColony = null) -> void:
	grid_cell = start_cell
	_movement = movement
	_colony = colony
	if display_name == "Goblin" and actor_id != "":
		display_name = _default_name_from_id(actor_id)
	hp = max_hp
	_sync_transform()
	set_selected(false)
	add_to_group(Defs.GROUP_GOBLIN)
	_ensure_nameplate()
	_attach_unit_visual()
	_update_status_visual()


func _attach_unit_visual() -> void:
	var path: String
	if is_hobgoblin_warrior:
		path = _VisualCatalog.GOBLIN_HOBGOBLIN_WARRIOR
	elif is_hobgoblin_mage:
		path = _VisualCatalog.GOBLIN_HOBGOBLIN_MAGE
	elif is_foblin():
		path = _VisualCatalog.GOBLIN_FOBLIN
	else:
		path = _VisualCatalog.GOBLIN_WORKER
	var scale := _VisualCatalog.unit_visual_scale(is_foblin(), is_hobgoblin_warrior, is_hobgoblin_mage)
	_VisualAttacher.attach_to_container(self, "VisualRoot", path, ["Body"], scale)


func is_foblin() -> bool:
	return is_foblin_unit


func is_alive() -> bool:
	return _alive and hp > 0


func should_flee() -> bool:
	if is_hobgoblin_warrior or is_hobgoblin_mage:
		return false
	return not is_foblin() and not is_militia


func is_hobgoblin() -> bool:
	return is_hobgoblin_warrior or is_hobgoblin_mage


func get_grid_cell() -> Vector2i:
	return grid_cell


func on_fed() -> void:
	starvation_level = maxf(0.0, starvation_level - 1.0)
	_update_status_visual()


func on_food_shortage() -> void:
	starvation_level += 1.0
	_update_status_visual()


func set_selected(selected: bool) -> void:
	var ring := get_node_or_null("VisualRoot/SelectionRing") as Node3D
	if ring != null:
		ring.visible = selected
		if selected and get_node_or_null("VisualRoot/ArtVisual") != null:
			ring.scale = Vector3(1.15, 1.0, 1.15)
		else:
			ring.scale = Vector3.ONE


func command_move(target_cell: Vector2i) -> void:
	_cancel_player_work()
	_player_owned = true
	_gather_chain = false
	_clear_job(true)
	job_kind = Defs.JobKind.MOVE
	_move_to(target_cell)


func command_gather(target: ResourceNode, jobs: JobService) -> void:
	_cancel_player_work()
	_player_owned = true
	_gather_chain = true
	if target != null:
		_chain_kind = target.resource_kind
	if target != null and target.try_reserve(actor_id):
		start_gather_job(target)
		return
	_try_assign_gather(jobs, target.grid_cell if target != null else grid_cell)


func command_build(site: ConstructionSite, jobs: JobService) -> void:
	_cancel_player_work()
	_player_owned = true
	_gather_chain = false
	if site != null and site.try_reserve(actor_id):
		start_build_job(site)
		return
	if jobs != null:
		var fallback := jobs.find_best_build_target(grid_cell, actor_id)
		if fallback != null and fallback.try_reserve(actor_id):
			start_build_job(fallback)


func tick_needs(delta: float) -> void:
	if not is_alive():
		return
	hunger = clampf(hunger + Constants.HUNGER_RATE * delta, 0.0, 100.0)
	energy = clampf(energy - Constants.ENERGY_DRAIN_RATE * delta, 0.0, 100.0)
	if starvation_level > 0.0:
		var dmg: float = Constants.STARVATION_DAMAGE * starvation_level * delta
		take_damage(int(ceil(dmg)), null)
	if damage_buff_timer > 0.0:
		damage_buff_timer = maxf(0.0, damage_buff_timer - delta)
	_update_status_visual()


func is_moving() -> bool:
	if _path.is_empty() or _path_index >= _path.size():
		return false
	var next_cell: Vector2i = _path[_path_index]
	return next_cell != grid_cell or _move_progress > 0.0


func dev_observation_extra() -> Dictionary:
	var destination := Vector2i(-1, -1)
	if not _path.is_empty():
		destination = _path[_path.size() - 1]
	var path_cells: Array[Vector2i] = []
	if _path_index < _path.size():
		for i in range(_path_index, _path.size()):
			path_cells.append(_path[i])
	return {
		"path_total": _path.size(),
		"path_index": _path_index,
		"path_remaining": maxi(0, _path.size() - _path_index),
		"path_destination": destination,
		"path_cells": path_cells,
		"player_owned": _player_owned,
		"gather_chain": _gather_chain,
		"target_label": _dev_target_label(),
		"idle_hint": _dev_idle_hint(),
	}


func tick_worker(delta: float, jobs: JobService) -> void:
	if not is_alive():
		return
	if damage_buff_timer > 0.0 and job_kind != Defs.JobKind.FIGHT:
		pass
	var enemy := _nearest_enemy(8.0)
	if enemy != null and (is_foblin() or is_militia or _near_guard_post()):
		_start_fight(enemy)
	if job_kind == Defs.JobKind.FIGHT:
		_tick_fight(delta)
		return
	if job_kind == Defs.JobKind.IDLE:
		if carried_amount > 0:
			_begin_deliver(jobs.find_nearest_storehouse(grid_cell))
		elif _gather_chain:
			_try_assign_gather(jobs, grid_cell)
		elif _player_owned:
			return
		else:
			jobs.assign_worker_job(self)
		if job_kind == Defs.JobKind.IDLE:
			return
	if worker_phase == Defs.WorkerPhase.WORK:
		_work_timer += delta * _work_speed_multiplier()
		match job_kind:
			Defs.JobKind.GATHER:
				_tick_gather_work(delta)
			Defs.JobKind.DELIVER:
				_tick_deliver_work()
			Defs.JobKind.BUILD:
				_tick_build_work(delta)
			Defs.JobKind.FORAGE:
				_tick_forage_work(delta)
			Defs.JobKind.PRAY:
				_tick_pray_work(delta)
	if worker_phase == Defs.WorkerPhase.MOVE:
		tick_movement(delta)
		if _path.is_empty() or _path_index >= _path.size():
			if job_kind == Defs.JobKind.MOVE:
				_finish_player_move()
			else:
				worker_phase = Defs.WorkerPhase.WORK
				_work_timer = 0.0


func start_gather_job(target: ResourceNode) -> void:
	_clear_job(false)
	_gather_target = target
	job_kind = Defs.JobKind.GATHER
	_move_to(target.interaction_cell(_movement))


func start_build_job(target: ConstructionSite) -> void:
	_clear_job(false)
	_build_target = target
	job_kind = Defs.JobKind.BUILD
	_move_to(target.interaction_cell(_movement))


func start_forage_job(target: ForagerPost) -> void:
	_clear_job(false)
	_forager_target = target
	job_kind = Defs.JobKind.FORAGE
	_move_to(target.interaction_cell(_movement))


func start_pray_job(target: ShrineBuilding) -> void:
	_clear_job(false)
	_shrine_target = target
	job_kind = Defs.JobKind.PRAY
	_move_to(target.interaction_cell(_movement))


func tick_movement(delta: float) -> void:
	if _path.is_empty() or _path_index >= _path.size():
		return
	var speed: float = Constants.FOBLIN_MOVE_SPEED if is_foblin() else Constants.GOBLIN_MOVE_SPEED
	var next_cell: Vector2i = _path[_path_index]
	if next_cell == grid_cell:
		_path_index += 1
		_move_progress = 0.0
		return
	_move_progress += delta * speed
	if _move_progress >= 1.0:
		grid_cell = next_cell
		_path_index += 1
		_move_progress = 0.0
		_sync_transform()
		return
	var from: Vector3 = _movement.grid_to_world(grid_cell)
	var to: Vector3 = _movement.grid_to_world(next_cell)
	global_position = from.lerp(to, _move_progress)
	_update_visual_facing(from, to)


func take_damage(amount: int, source: Node) -> void:
	if not is_alive():
		return
	hp = maxi(0, hp - amount)
	_update_status_visual()
	if should_flee() and source != null and job_kind != Defs.JobKind.FIGHT:
		var flee_cell := grid_cell + Vector2i(randi_range(-3, 3), randi_range(-3, 3))
		command_move(flee_cell)
	if hp <= 0:
		_die(source)


func apply_damage_buff(duration: float, mult: float) -> void:
	damage_buff_timer = duration
	attack_damage = int(float(Constants.GOBLIN_ATTACK_DAMAGE if not is_foblin() else Constants.FOBLIN_ATTACK_DAMAGE) * mult)


func _die(killer: Node) -> void:
	_alive = false
	_clear_job(true)
	job_kind = Defs.JobKind.IDLE
	Bus.goblin_died.emit(self, killer)
	if _colony != null:
		_colony.on_goblin_died(self)
	queue_free()


func _begin_deliver(store: Storehouse) -> void:
	if store == null:
		_reset_idle()
		return
	_storehouse = store
	job_kind = Defs.JobKind.DELIVER
	_move_to(store.interaction_cell(_movement))


func _tick_gather_work(delta: float) -> void:
	if _gather_target == null or not is_instance_valid(_gather_target):
		_reset_idle()
		return
	if _gather_target is TreeResource:
		var tree := _gather_target as TreeResource
		if not tree.is_felled():
			if tree.add_fell_progress(delta):
				_work_timer = 0.0
			return
		if not tree.can_gather_now():
			return
	if _work_timer < Constants.GATHER_TIME:
		return
	var space: int = Constants.CARRY_CAPACITY - carried_amount
	var amount: int = mini(space, Constants.GATHER_AMOUNT)
	var taken: int = _gather_target.gather(int(amount * gather_multiplier * crowding_work_multiplier))
	if taken <= 0:
		if _gather_target is TreeResource and not (_gather_target as TreeResource).can_gather_now():
			return
		_release_gather()
		_reset_idle()
		return
	var kind: Defs.ResourceKind = _gather_target.resource_kind
	var node_depleted: bool = _gather_target.remaining <= 0
	var continue_cell: Vector2i = _gather_target.interaction_cell(_movement)
	carried_kind = kind
	carried_amount += taken
	if carried_amount >= Constants.CARRY_CAPACITY or node_depleted:
		_release_gather()
		var store := Services.storehouse
		if store == null:
			store = _find_storehouse()
		_begin_deliver(store)
	else:
		worker_phase = Defs.WorkerPhase.MOVE
		_move_to(continue_cell)
		_work_timer = 0.0


func _tick_deliver_work() -> void:
	if _storehouse == null or not is_instance_valid(_storehouse):
		_storehouse = _find_storehouse()
	if _storehouse == null:
		_reset_idle()
		return
	_storehouse.deposit(carried_kind, carried_amount)
	carried_amount = 0
	_reset_idle()


func _tick_build_work(_delta: float) -> void:
	if _work_timer < Constants.BUILD_WORK_TIME:
		return
	if _build_target == null or not is_instance_valid(_build_target):
		_reset_idle()
		return
	var progress: float = (
		_build_target.definition.build_progress_per_work_tick()
		* build_multiplier
		* crowding_work_multiplier
	)
	_build_target.add_build_progress(progress)
	if _build_target.is_complete():
		_release_build()
		_finish_player_build()
		return
	_work_timer = 0.0


func _tick_forage_work(_delta: float) -> void:
	if _forager_target == null or not is_instance_valid(_forager_target):
		_reset_idle()
		return
	if _work_timer < Constants.FORAGE_WORK_TIME:
		return
	_forager_target.forage()
	_release_forage()
	_reset_idle()


func _tick_pray_work(_delta: float) -> void:
	if _shrine_target == null or not is_instance_valid(_shrine_target):
		_reset_idle()
		return
	if _work_timer < Constants.PRAY_WORK_TIME:
		return
	_shrine_target.pray()
	_release_shrine()
	_reset_idle()


func _tick_fight(delta: float) -> void:
	var enemy := _nearest_enemy(10.0)
	if enemy == null:
		_reset_idle()
		return
	var dist: float = global_position.distance_to(enemy.global_position)
	if dist > Constants.ENEMY_ATTACK_RANGE:
		if enemy is EnemyUnit:
			_move_to((enemy as EnemyUnit).grid_cell)
		tick_movement(delta)
		return
	_attack_timer = maxf(0.0, _attack_timer - delta)
	if _attack_timer <= 0.0 and enemy.has_method("take_damage"):
		var dmg: int = attack_damage
		if damage_buff_timer > 0.0:
			dmg = int(float(dmg) * Constants.BLESS_DEFENDER_DAMAGE_MULT)
		if _has_blacksmith():
			dmg = int(float(dmg) * Constants.BLACKSMITH_ATTACK_MULTIPLIER)
		enemy.call("take_damage", dmg, self)
		_attack_timer = Constants.ENEMY_ATTACK_COOLDOWN


func _has_blacksmith() -> bool:
	var tree := get_tree()
	if tree == null:
		return false
	return not tree.get_nodes_in_group(Defs.GROUP_BLACKSMITH).is_empty()


func _start_fight(enemy: Node3D) -> void:
	if enemy == null:
		return
	_clear_job(true)
	job_kind = Defs.JobKind.FIGHT
	worker_phase = Defs.WorkerPhase.WORK
	_attack_timer = 0.0


func _move_to(target_cell: Vector2i) -> void:
	worker_phase = Defs.WorkerPhase.MOVE
	var raw: Array[Vector2i] = _movement.find_path(grid_cell, target_cell)
	_path = []
	_path_index = 0
	_move_progress = 0.0
	if raw.size() <= 1:
		worker_phase = Defs.WorkerPhase.WORK
		_work_timer = 0.0
		return
	for i in range(1, raw.size()):
		_path.append(raw[i])
	if not _path.is_empty():
		var from: Vector3 = _movement.grid_to_world(grid_cell)
		var to: Vector3 = _movement.grid_to_world(_path[0])
		_update_visual_facing(from, to)


func _release_gather() -> void:
	if _gather_target != null and is_instance_valid(_gather_target):
		_gather_target.release_reservation(actor_id)
	_gather_target = null


func _release_build() -> void:
	if _build_target != null and is_instance_valid(_build_target):
		_build_target.release_reservation(actor_id)
	_build_target = null


func _release_forage() -> void:
	if _forager_target != null and is_instance_valid(_forager_target):
		_forager_target.release_reservation(actor_id)
	_forager_target = null


func _release_shrine() -> void:
	if _shrine_target != null and is_instance_valid(_shrine_target):
		_shrine_target.release_reservation(actor_id)
	_shrine_target = null


func _clear_job(release: bool) -> void:
	if release:
		_release_gather()
		_release_build()
		_release_forage()
		_release_shrine()
	_path = []
	_path_index = 0
	_work_timer = 0.0


func _reset_idle() -> void:
	_clear_job(true)
	job_kind = Defs.JobKind.IDLE
	worker_phase = Defs.WorkerPhase.IDLE
	_storehouse = null


func _dev_target_label() -> String:
	if _gather_target != null and is_instance_valid(_gather_target):
		return "gather@%s" % _gather_target.grid_cell
	if _build_target != null and is_instance_valid(_build_target):
		return "build@%s" % _build_target.grid_cell
	if _forager_target != null and is_instance_valid(_forager_target):
		return "forage@%s" % _forager_target.grid_cell
	if _shrine_target != null and is_instance_valid(_shrine_target):
		return "shrine@%s" % _shrine_target.grid_cell
	if _storehouse != null and is_instance_valid(_storehouse):
		return "deliver@%s" % _storehouse.grid_cell
	if job_kind == Defs.JobKind.MOVE and not _path.is_empty():
		return "move@%s" % _path[_path.size() - 1]
	if job_kind == Defs.JobKind.FIGHT:
		return "fight"
	return "none"


func _dev_idle_hint() -> String:
	if job_kind != Defs.JobKind.IDLE:
		return ""
	if carried_amount > 0:
		return "pending_deliver"
	if _player_owned:
		return "player_command_wait"
	if _gather_chain:
		return "gather_chain_no_target"
	return "awaiting_assignment"


func _finish_player_move() -> void:
	_reset_idle()
	_player_owned = false


func _finish_player_build() -> void:
	_reset_idle()
	_player_owned = false


func _cancel_player_work() -> void:
	_clear_job(true)
	_reset_idle()


func _try_assign_gather(jobs: JobService, near_cell: Vector2i) -> void:
	if jobs == null:
		return
	var target := jobs.find_best_gather_target_of_kind(grid_cell, actor_id, _chain_kind, near_cell)
	if target != null and target.try_reserve(actor_id):
		start_gather_job(target)
		return
	if _gather_chain:
		_player_owned = true
		job_kind = Defs.JobKind.IDLE


func _find_storehouse() -> Storehouse:
	var jobs := Services.job_service
	if jobs != null:
		return jobs.find_nearest_storehouse(grid_cell)
	var best: Storehouse = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_STOREHOUSE):
		if not node is Storehouse:
			continue
		var store := node as Storehouse
		var dist: float = float((grid_cell - store.grid_cell).length_squared())
		if dist < best_dist:
			best_dist = dist
			best = store
	return best


func _work_speed_multiplier() -> float:
	if starvation_level > 0.0:
		return Constants.STARVATION_WORK_SLOW
	return 1.0


func _nearest_enemy(radius: float) -> Node3D:
	var best: Node3D = null
	var best_dist: float = radius * radius
	for node in get_tree().get_nodes_in_group(Defs.GROUP_ENEMY):
		if not node is EnemyUnit:
			continue
		var enemy := node as EnemyUnit
		var dist: float = global_position.distance_squared_to(enemy.global_position)
		if dist <= best_dist:
			best_dist = dist
			best = enemy
	return best


func _near_guard_post() -> bool:
	for node in get_tree().get_nodes_in_group(Defs.GROUP_BUILDING):
		if node is GuardPost:
			var post := node as GuardPost
			var dist: float = float((grid_cell - post.grid_cell).length_squared())
			if dist <= post.guard_radius_tiles() * post.guard_radius_tiles():
				return true
	return false


func _default_name_from_id(id: String) -> String:
	var parts: PackedStringArray = id.split("_")
	if parts.size() >= 2:
		var index: int = int(parts[1]) % Constants.GOBLIN_NAMES.size()
		return Constants.GOBLIN_NAMES[index]
	return "Goblin"


func _sync_transform() -> void:
	global_position = _movement.grid_to_world(grid_cell)


func _update_visual_facing(from: Vector3, to: Vector3) -> void:
	var visual := get_node_or_null("VisualRoot") as Node3D
	if visual == null:
		return
	var dir := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if dir.length_squared() < 0.0001:
		return
	visual.rotation.y = atan2(dir.x, dir.z) + Constants.UNIT_VISUAL_YAW_OFFSET


func _ensure_nameplate() -> void:
	var label := get_node_or_null("NameLabel3D") as Label3D
	if label == null:
		label = Label3D.new()
		label.name = "NameLabel3D"
		label.font_size = 28
		label.position = Vector3(0.0, 1.15, 0.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.outline_size = 4
		label.modulate = Color(0.95, 0.95, 0.85)
		add_child(label)
	label.text = "Foblin" if is_foblin() else display_name


func _default_body_color() -> Color:
	if is_foblin():
		return Color(0.35, 0.55, 0.25)
	return Color(0.42, 0.58, 0.32)


func _update_status_visual() -> void:
	var body := get_node_or_null("VisualRoot/Body") as CSGBox3D
	var has_art := get_node_or_null("VisualRoot/ArtVisual") != null
	if body != null:
		body.visible = not has_art
		if not has_art:
			var mat := body.material as StandardMaterial3D
			if mat == null:
				mat = StandardMaterial3D.new()
				body.material = mat
			if not is_alive():
				mat.albedo_color = Color(0.2, 0.2, 0.2)
			elif starvation_level >= 2.0:
				mat.albedo_color = Color(0.85, 0.25, 0.18)
			elif starvation_level > 0.0:
				mat.albedo_color = Color(0.75, 0.45, 0.2)
			elif hp <= max_hp / 3:
				mat.albedo_color = Color(0.55, 0.2, 0.2)
			elif damage_buff_timer > 0.0:
				mat.albedo_color = Color(0.85, 0.75, 0.25)
			else:
				mat.albedo_color = _default_body_color()
	var label := get_node_or_null("NameLabel3D") as Label3D
	if label != null:
		var suffix := ""
		if starvation_level > 0.0:
			suffix = " *"
		label.text = ("Foblin" if is_foblin() else display_name) + suffix
		label.modulate = Color(1.0, 0.45, 0.35) if starvation_level > 0.0 else Color(0.95, 0.95, 0.85)
