class_name Stockpile
extends RefCounted

## Colony resource totals.

var amounts: Dictionary = {
	Defs.ResourceKind.GOLD: 0,
	Defs.ResourceKind.WOOD: 0,
	Defs.ResourceKind.STONE: 0,
	Defs.ResourceKind.FOOD: 0,
	Defs.ResourceKind.MAGIC: 0,
	Defs.ResourceKind.BONES: 0,
}


func get_amount(kind: Defs.ResourceKind) -> int:
	return int(amounts.get(kind, 0))


func can_afford(cost: Dictionary) -> bool:
	for kind in cost:
		if get_amount(int(kind)) < int(cost[kind]):
			return false
	return true


func spend(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for kind in cost:
		amounts[int(kind)] = get_amount(int(kind)) - int(cost[kind])
	return true


func deposit(kind: Defs.ResourceKind, amount: int) -> void:
	if amount <= 0:
		return
	amounts[kind] = get_amount(kind) + amount
	Bus.resource_deposited.emit(kind, amount, get_amount(kind))


func try_spend(kind: Defs.ResourceKind, amount: int) -> bool:
	return spend({kind: amount})
