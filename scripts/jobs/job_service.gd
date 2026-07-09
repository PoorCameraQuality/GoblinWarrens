class_name JobService
extends Node

## Assigns gather, deliver, build, forage, and pray work to idle goblin workers.

var _movement: MovementAdapter = null
var _storehouse: Storehouse = null
var _colony: GoblinWarrenColony = null


func setup(movement: MovementAdapter, storehouse: Storehouse, colony: GoblinWarrenColony = null) -> void:
	_movement = movement
	_storehouse = storehouse
	_colony = colony


func find_storehouse(from_cell: Vector2i = Vector2i.ZERO) -> Storehouse:
	return find_nearest_storehouse(from_cell)


func find_nearest_storehouse(from_cell: Vector2i) -> Storehouse:
	var best: Storehouse = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_STOREHOUSE):
		if not node is Storehouse:
			continue
		var store := node as Storehouse
		if not is_instance_valid(store):
			continue
		var dist: float = float((from_cell - store.grid_cell).length_squared())
		if dist < best_dist:
			best_dist = dist
			best = store
	if best != null:
		_storehouse = best
	return best


func find_best_gather_target(from_cell: Vector2i, worker_id: String) -> ResourceNode:
	return find_best_gather_target_of_kind(from_cell, worker_id, -1, from_cell)


func find_best_gather_target_of_kind(
	from_cell: Vector2i,
	worker_id: String,
	kind: int,
	near_cell: Vector2i
) -> ResourceNode:
	var ready_logs_exist := _any_gather_ready_trees()
	var best: ResourceNode = null
	var best_score: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_RESOURCE_NODE):
		if not node is ResourceNode:
			continue
		var resource := node as ResourceNode
		if not resource.is_available():
			continue
		if kind >= 0 and int(resource.resource_kind) != kind:
			continue
		if resource.is_reserved_by(worker_id):
			continue
		if ready_logs_exist and resource is TreeResource:
			var tree := resource as TreeResource
			if not tree.can_gather_now():
				continue
		var dist_worker: float = float((from_cell - resource.grid_cell).length_squared())
		var dist_hint: float = float((near_cell - resource.grid_cell).length_squared())
		var score: float = dist_worker + dist_hint * 0.25
		score += _gather_target_bias(resource)
		if score < best_score:
			best_score = score
			best = resource
	return best


func _any_gather_ready_trees() -> bool:
	for node in get_tree().get_nodes_in_group(Defs.GROUP_RESOURCE_NODE):
		if node is TreeResource and (node as TreeResource).can_gather_now():
			return true
	return false


func _gather_target_bias(resource: ResourceNode) -> float:
	if resource is TreeResource:
		var tree := resource as TreeResource
		if tree.can_gather_now():
			return -1_000_000.0
		if tree.is_felled():
			return -500_000.0
		return 500_000.0
	return 0.0


func find_best_build_target(from_cell: Vector2i, worker_id: String) -> ConstructionSite:
	var best: ConstructionSite = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_CONSTRUCTION):
		if not node is ConstructionSite:
			continue
		var site := node as ConstructionSite
		if site.is_complete() or not site.resources_paid:
			continue
		if site.is_reserved_by(worker_id):
			continue
		var dist: float = float((from_cell - site.grid_cell).length_squared())
		if dist < best_dist:
			best_dist = dist
			best = site
	return best


func find_best_forager_post(from_cell: Vector2i, worker_id: String) -> ForagerPost:
	var best: ForagerPost = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_FORAGER_POST):
		if not node is ForagerPost:
			continue
		var post := node as ForagerPost
		if post.is_reserved_by(worker_id):
			continue
		var dist: float = float((from_cell - post.grid_cell).length_squared())
		if dist < best_dist:
			best_dist = dist
			best = post
	return best


func find_best_shrine(from_cell: Vector2i, worker_id: String) -> ShrineBuilding:
	var best: ShrineBuilding = null
	var best_dist: float = INF
	for node in get_tree().get_nodes_in_group(Defs.GROUP_SHRINE):
		if not node is ShrineBuilding:
			continue
		var shrine := node as ShrineBuilding
		if shrine.is_reserved_by(worker_id):
			continue
		var dist: float = float((from_cell - shrine.grid_cell).length_squared())
		if dist < best_dist:
			best_dist = dist
			best = shrine
	return best


func assign_worker_job(goblin: Goblin) -> void:
	if goblin == null or _movement == null:
		return
	var build_target := find_best_build_target(goblin.grid_cell, goblin.actor_id)
	if build_target != null and build_target.try_reserve(goblin.actor_id):
		goblin.start_build_job(build_target)
		return
	if _should_forage():
		var forager := find_best_forager_post(goblin.grid_cell, goblin.actor_id)
		if forager != null and forager.try_reserve(goblin.actor_id):
			goblin.start_forage_job(forager)
			return
	if _should_pray():
		var shrine := find_best_shrine(goblin.grid_cell, goblin.actor_id)
		if shrine != null and shrine.try_reserve(goblin.actor_id):
			goblin.start_pray_job(shrine)
			return
	var gather_target := find_best_gather_target(goblin.grid_cell, goblin.actor_id)
	if gather_target != null and gather_target.try_reserve(goblin.actor_id):
		goblin.start_gather_job(gather_target)


func _should_forage() -> bool:
	if _colony == null:
		return false
	var stock := _colony.get_stockpile()
	if stock == null:
		return false
	var goblins: int = _colony.count_living_goblins()
	if goblins <= 0:
		return false
	var reserve: int = goblins * Constants.FOOD_PER_GOBLIN_PER_TICK * 2
	return stock.get_amount(Defs.ResourceKind.FOOD) < reserve


func _should_pray() -> bool:
	if _colony == null:
		return false
	if not _colony.has_building_kind(Defs.BuildingKind.SHRINE):
		return false
	var stock := _colony.get_stockpile()
	if stock == null:
		return false
	return stock.get_amount(Defs.ResourceKind.MAGIC) < 15
