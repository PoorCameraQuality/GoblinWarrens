class_name ThreatScheduler
extends Node

## Day-based threat events for the MVP demo arc.

enum Phase {
	IDLE,
	SCOUTING,
	RAID_ACTIVE,
}

var phase: Phase = Phase.IDLE
var _colony: GoblinWarrenColony
var _day_sim: DaySimulation
var _strategic_map = null ## CompiledStrategicMap when authored map is active
var _scout_timer: float = 0.0
var _raid_cleared: bool = false


func setup(colony: GoblinWarrenColony, day_sim: DaySimulation, strategic_map = null) -> void:
	_colony = colony
	_day_sim = day_sim
	_strategic_map = strategic_map
	if _day_sim != null:
		_day_sim.day_changed.connect(_on_day_changed)


func _on_day_changed(day: int) -> void:
	if _colony == null:
		return
	match day:
		2:
			_colony.spawn_enemy(Defs.EnemyKind.BEAST, _spawn_cell_for_kind(Defs.EnemyKind.BEAST, 0))
			Bus.threat_warning.emit("A surface beast prowls nearby!")
		6:
			_colony.spawn_enemy(Defs.EnemyKind.SCOUT, _spawn_cell_for_kind(Defs.EnemyKind.SCOUT, 0))
			var lead: float = _colony.get_watchtower_warning_bonus()
			var until_raid: float = maxf(60.0, Constants.SECONDS_PER_DAY - lead)
			var mins: int = int(ceil(until_raid / 60.0))
			Bus.threat_warning.emit(
				"Human scout spotted! Raid expected in ~%d min." % mins
			)
		7:
			_start_raid()


func _start_raid() -> void:
	phase = Phase.RAID_ACTIVE
	_raid_cleared = false
	Bus.raid_started.emit(_day_sim.current_day if _day_sim != null else 7)
	Bus.threat_warning.emit("Human militia raid incoming!")
	for i in range(Constants.RAID_MILITIA_COUNT):
		_colony.spawn_enemy(Defs.EnemyKind.MILITIA, _spawn_cell_for_kind(Defs.EnemyKind.MILITIA, i))


func notify_enemy_died() -> void:
	if phase != Phase.RAID_ACTIVE:
		return
	if _colony.count_enemies() <= 0:
		_raid_cleared = true
		phase = Phase.IDLE
		Bus.raid_ended.emit(true)
		_colony.on_raid_survived()


func is_raid_cleared() -> bool:
	return _raid_cleared


func is_raid_active() -> bool:
	return phase == Phase.RAID_ACTIVE


func _spawn_cell_for_kind(kind: Defs.EnemyKind, index: int) -> Vector2i:
	if _strategic_map != null:
		var authored: Vector2i = Vector2i(-1, -1)
		match kind:
			Defs.EnemyKind.MILITIA, Defs.EnemyKind.SCOUT, Defs.EnemyKind.BEAST:
				authored = _strategic_map.pick_raid_cell(index)
		if authored.x >= 0:
			return authored
	return Vector2i(Constants.GRID_WIDTH - 2, randi_range(2, Constants.GRID_HEIGHT - 3))


func dev_trigger_raid() -> void:
	if not OS.is_debug_build():
		return
	_start_raid()
