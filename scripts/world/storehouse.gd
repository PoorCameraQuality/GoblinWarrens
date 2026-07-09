class_name Storehouse
extends Building

## Drop-off for gathered resources. Deposits into the colony stockpile.

var stockpile: Stockpile = Stockpile.new()


func _ready() -> void:
	super._ready()
	add_to_group(Defs.GROUP_STOREHOUSE)


func setup_store(cell: Vector2i, def: BuildingDef = null, shared: Stockpile = null) -> void:
	if shared != null:
		stockpile = shared
	if def == null:
		def = BuildingCatalog.storehouse()
	setup(cell, def)


func deposit(kind: Defs.ResourceKind, amount: int) -> void:
	stockpile.deposit(kind, amount)


func interaction_cell(movement: MovementAdapter) -> Vector2i:
	var approach: Vector2i = grid_cell + Vector2i(footprint.x, 0)
	return movement.nearest_reachable(approach, grid_cell)
