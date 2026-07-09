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
var _scout_timer: float = 0.0
var _raid_cleared: bool = false


func setup(colony: GoblinWarrenColony, day_sim: DaySimulation) -> void:
	_colony = colony
	_day_sim = day_sim
	if _day_sim != null:
		_day_sim.day_changed.connect(_on_day_changed)


func _on_day_changed(day: int) -> void:
	if _colony == null:
		return
	match day:
		2:
			_colony.spawn_enemy(Defs.EnemyKind.BEAST)
			Bus.threat_warning.emit("A surface beast prowls nearby!")
		6:
			_colony.spawn_enemy(Defs.EnemyKind.SCOUT)
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
		_colony.spawn_enemy(Defs.EnemyKind.MILITIA)


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


func dev_trigger_raid() -> void:
	if not OS.is_debug_build():
		return
	_start_raid()
