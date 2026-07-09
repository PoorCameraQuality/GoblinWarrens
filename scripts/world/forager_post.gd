class_name ForagerPost
extends Building

## Worker foraging station — goblins work here to add food to the stockpile.

var _stockpile: Stockpile = null
var reserved_by: String = ""


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_FORAGER_POST)


func setup_post(cell: Vector2i, def: BuildingDef, stockpile: Stockpile) -> void:
	setup(cell, def)
	_stockpile = stockpile


func is_reserved_by(other_id: String) -> bool:
	return not reserved_by.is_empty() and reserved_by != other_id


func try_reserve(worker_id: String) -> bool:
	if is_reserved_by(worker_id):
		return false
	reserved_by = worker_id
	return true


func release_reservation(worker_id: String) -> void:
	if reserved_by == worker_id:
		reserved_by = ""


func forage() -> int:
	if _stockpile == null:
		return 0
	var amount: int = Constants.FORAGE_FOOD_PER_ACTION
	_stockpile.deposit(Defs.ResourceKind.FOOD, amount)
	return amount
