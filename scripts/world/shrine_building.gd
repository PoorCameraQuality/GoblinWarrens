class_name ShrineBuilding
extends Building

## Prayer and passive magic generation.

var _stockpile: Stockpile = null
var reserved_by: String = ""
var _magic_accum: float = 0.0


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_SHRINE)


func setup_shrine(cell: Vector2i, def: BuildingDef, stockpile: Stockpile) -> void:
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


func pray() -> int:
	if _stockpile == null:
		return 0
	_stockpile.deposit(Defs.ResourceKind.MAGIC, Constants.PRAY_MAGIC_GAIN)
	return Constants.PRAY_MAGIC_GAIN


func tick_passive(delta: float) -> void:
	if _stockpile == null:
		return
	_magic_accum += delta * Constants.SHRINE_PASSIVE_MAGIC_PER_SECOND
	while _magic_accum >= 1.0:
		_stockpile.deposit(Defs.ResourceKind.MAGIC, 1)
		_magic_accum -= 1.0
