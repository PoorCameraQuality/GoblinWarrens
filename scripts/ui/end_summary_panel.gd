class_name EndSummaryPanel
extends Control

## MVP win/loss end screen.

@onready var _title: Label = $Panel/Margin/VBox/TitleLabel
@onready var _body: Label = $Panel/Margin/VBox/BodyLabel
@onready var _restart: Button = $Panel/Margin/VBox/RestartButton


func _ready() -> void:
	visible = false
	if _restart != null:
		_restart.pressed.connect(_on_restart)


func show_summary(colony: GoblinWarrenColony, outcome: Defs.DemoOutcome) -> void:
	if colony == null:
		return
	visible = true
	var stats: ColonyStats = colony.get_stats()
	var stock := colony.get_stockpile()
	var win: bool = outcome == Defs.DemoOutcome.WIN
	if _title != null:
		_title.text = "Victory!" if win else "The warren falls..."
	if _body != null:
		_body.text = (
			"Day: %d\nSurvivors: %d\nDeaths: %d\nRevivals: %d\nBuildings: %d\n"
			+ "Food: %d\nMagic: %d\nEnemies slain: %d\nRaids survived: %d"
		) % [
			colony.get_current_day(),
			colony.count_living_goblins(),
			stats.deaths,
			stats.revivals,
			stats.buildings_built,
			stock.get_amount(Defs.ResourceKind.FOOD) if stock != null else 0,
			stock.get_amount(Defs.ResourceKind.MAGIC) if stock != null else 0,
			stats.enemies_killed,
			stats.raids_survived,
		]


func _on_restart() -> void:
	get_tree().reload_current_scene()
