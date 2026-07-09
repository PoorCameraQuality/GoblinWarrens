class_name DaySimulation
extends Node

## Advances in-game days for the MVP demo arc.

signal day_changed(day: int)

var current_day: int = 1
var _elapsed: float = 0.0


func tick(delta: float) -> void:
	_elapsed += delta
	if _elapsed < Constants.SECONDS_PER_DAY:
		return
	_elapsed -= Constants.SECONDS_PER_DAY
	current_day += 1
	day_changed.emit(current_day)
	Bus.day_advanced.emit(current_day)


func seconds_until_next_day() -> float:
	return maxf(0.0, Constants.SECONDS_PER_DAY - _elapsed)


func day_progress() -> float:
	return clampf(_elapsed / Constants.SECONDS_PER_DAY, 0.0, 1.0)


func reset() -> void:
	current_day = 1
	_elapsed = 0.0


func force_advance_day() -> void:
	current_day += 1
	_elapsed = 0.0
	day_changed.emit(current_day)
	Bus.day_advanced.emit(current_day)
