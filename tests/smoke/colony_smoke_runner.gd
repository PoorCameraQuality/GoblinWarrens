extends Node

## Runs colony for N sim seconds, then exits. Used by test_colony.gd smoke harness.
## Milestone 1: verifies workers stay alive and stockpile totals increase (gather-return-store).

const COLONY_SCENE := preload("res://scenes/colony.tscn")
const RUN_SECONDS := 90.0 ## sim seconds after colony ready; excludes procgen startup

var _sim_elapsed: float = 0.0
var _sim_ready: bool = false
var _baseline: Dictionary = {}
var _baseline_captured: bool = false


func _ready() -> void:
	add_child(COLONY_SCENE.instantiate())


func _physics_process(delta: float) -> void:
	var colony: Node = get_child(0)
	if not _sim_ready:
		if _colony_sim_ready(colony):
			_sim_ready = true
			_capture_baseline(colony)
		return
	_sim_elapsed += delta
	if _sim_elapsed < RUN_SECONDS:
		return
	_assert_milestone_one(colony)


func _colony_sim_ready(colony: Node) -> bool:
	if not colony.has_method("get_stockpile"):
		return false
	if colony.get_stockpile() == null:
		return false
	var goblins_root: Node = colony.get_node_or_null("Goblins")
	return goblins_root != null and goblins_root.get_child_count() > 0


func _capture_baseline(colony: Node) -> void:
	if not colony.has_method("get_stockpile"):
		push_error("[colony-smoke] colony missing get_stockpile()")
		get_tree().quit(1)
		return
	var stock: Stockpile = colony.get_stockpile()
	if stock == null:
		push_error("[colony-smoke] no stockpile after setup")
		get_tree().quit(1)
		return
	_baseline = {
		Defs.ResourceKind.GOLD: stock.get_amount(Defs.ResourceKind.GOLD),
		Defs.ResourceKind.WOOD: stock.get_amount(Defs.ResourceKind.WOOD),
		Defs.ResourceKind.STONE: stock.get_amount(Defs.ResourceKind.STONE),
	}
	_baseline_captured = true


func _assert_milestone_one(colony: Node) -> void:
	var goblins_root: Node = colony.get_node_or_null("Goblins")
	if goblins_root == null or goblins_root.get_child_count() < 1:
		push_error("[colony-smoke] expected at least one goblin alive")
		get_tree().quit(1)
		return
	var stock: Stockpile = colony.get_stockpile()
	if stock == null:
		push_error("[colony-smoke] no stockpile at end of run")
		get_tree().quit(1)
		return
	var increased := false
	for kind in _baseline:
		var after: int = stock.get_amount(int(kind))
		if after > int(_baseline[kind]):
			increased = true
			break
	if not increased:
		push_error(
			"[colony-smoke] stockpile did not increase (gold %d wood %d stone %d)" % [
				stock.get_amount(Defs.ResourceKind.GOLD),
				stock.get_amount(Defs.ResourceKind.WOOD),
				stock.get_amount(Defs.ResourceKind.STONE),
			]
		)
		get_tree().quit(1)
		return
	print("[colony-smoke] ok")
	get_tree().quit(0)
