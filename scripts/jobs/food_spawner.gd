class_name FoodSpawner
extends Node

## Spawns food markers on random walkable tiles.

const FOOD_SCENE := preload("res://scenes/world/food.tscn")

var _movement: MovementAdapter = null
var _timer: float = 0.0
var _rng := RandomNumberGenerator.new()


func setup(movement: MovementAdapter) -> void:
	_movement = movement
	_rng.randomize()


func tick(delta: float, food_root: Node3D) -> void:
	if _movement == null:
		return
	_timer += delta
	if _timer < Constants.FOOD_SPAWN_INTERVAL:
		return
	_timer = 0.0
	var existing := food_root.get_child_count()
	if existing >= Constants.MAX_FOOD_ON_MAP:
		return
	var cell := _random_open_cell()
	if cell == Vector2i(-1, -1):
		return
	var food := FOOD_SCENE.instantiate() as Node3D
	food.global_position = _movement.grid_to_world(cell)
	food_root.add_child(food)
	Bus.food_spawned.emit(food)


func _random_open_cell() -> Vector2i:
	for _attempt in range(32):
		var cell := Vector2i(
			_rng.randi_range(0, Constants.GRID_WIDTH - 1),
			_rng.randi_range(0, Constants.GRID_HEIGHT - 1),
		)
		if not _movement.is_in_bounds(cell):
			continue
		if not _movement.is_walkable(cell):
			continue
		return cell
	return Vector2i(-1, -1)
