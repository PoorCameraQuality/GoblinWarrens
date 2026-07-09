class_name GoblinWarrensDebugRouter
extends RefCounted

## Dev cheat dispatch — calls colony systems only. See docs/technical/DEBUG_COMMANDS.md.


static func resolve_colony(from: Node) -> GoblinWarrenColony:
	if from == null:
		return null
	if from is GoblinWarrenColony:
		return from as GoblinWarrenColony
	return from.get_tree().current_scene as GoblinWarrenColony


static func add_food(from: Node, amount: int = 20) -> void:
	_deposit(from, Defs.ResourceKind.FOOD, amount)


static func add_wood(from: Node, amount: int = 20) -> void:
	_deposit(from, Defs.ResourceKind.WOOD, amount)


static func add_stone(from: Node, amount: int = 20) -> void:
	_deposit(from, Defs.ResourceKind.STONE, amount)


static func add_magic(from: Node, amount: int = 10) -> void:
	_deposit(from, Defs.ResourceKind.MAGIC, amount)


static func skip_day(from: Node) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.dev_skip_day()


static func start_raid(from: Node) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.dev_start_raid()


static func spawn_beast(from: Node) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.dev_spawn_beast()


static func damage_warren(from: Node, amount: int = 25) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.dev_damage_warren(amount)


static func heal_warren(from: Node) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.dev_heal_warren()


static func revive_goblin(from: Node) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.try_revive_goblin()


static func _deposit(from: Node, kind: Defs.ResourceKind, amount: int) -> void:
	var colony := resolve_colony(from)
	if colony != null:
		colony.dev_add_resource(kind, amount)
