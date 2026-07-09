extends Node

## Thin global event bus. Prefer typed signals on domain nodes when possible.

signal tick_advanced(tick: int)
signal goblin_spawned(goblin: Node)
signal goblin_died(goblin: Node, killer: Node)
signal goblin_revived(goblin: Node)
signal resource_deposited(kind: int, amount: int, total: int)
signal building_completed(kind: int, cell: Vector2i)
signal construction_started(kind: int, cell: Vector2i)
signal food_shortage(tick: int)
signal day_advanced(day: int)
signal threat_warning(message: String)
signal raid_started(day: int)
signal raid_ended(victory: bool)
signal warren_destroyed
signal demo_finished(outcome: int)
signal ritual_cast(name: String)
