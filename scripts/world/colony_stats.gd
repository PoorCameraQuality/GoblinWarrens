class_name ColonyStats
extends RefCounted

## Run statistics for the MVP end summary.

var deaths: int = 0
var revivals: int = 0
var enemies_killed: int = 0
var buildings_built: int = 0
var raids_survived: int = 0
var death_records: Array[DeathRecord] = []


func record_death(goblin: Goblin, day: int) -> void:
	if goblin == null or goblin.is_foblin():
		return
	deaths += 1
	var record := DeathRecord.new()
	record.actor_id = goblin.actor_id
	record.display_name = goblin.display_name
	record.day_died = day
	death_records.append(record)


func record_building() -> void:
	buildings_built += 1


func record_enemy_kill() -> void:
	enemies_killed += 1


func record_revival(goblin: Goblin) -> void:
	revivals += 1
	for record in death_records:
		if record.actor_id == goblin.actor_id:
			record.revived = true
			break


func unburied_proper_goblins() -> Array[DeathRecord]:
	var result: Array[DeathRecord] = []
	for record in death_records:
		if not record.revived and record.buried:
			result.append(record)
	return result


func revivable_records() -> Array[DeathRecord]:
	var result: Array[DeathRecord] = []
	for record in death_records:
		if not record.revived and record.buried:
			result.append(record)
	return result
