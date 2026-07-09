class_name BurialGrounds
extends Building

## Processes dead goblins into bones and enables revival.

var _stockpile: Stockpile = null


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_BURIAL)


func setup_burial(cell: Vector2i, def: BuildingDef, stockpile: Stockpile) -> void:
	setup(cell, def)
	_stockpile = stockpile


func bury_record(record: DeathRecord) -> void:
	if record == null or record.buried or record.revived:
		return
	record.buried = true
	if _stockpile != null:
		_stockpile.deposit(Defs.ResourceKind.BONES, 1)
