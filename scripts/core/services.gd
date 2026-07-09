extends Node

## Thin service locator. Systems register here; avoid turning this into a god object.

var movement: MovementAdapter = null
var job_service: JobService = null
var storehouse: Storehouse = null
var map_plan: MapPlan = null


func register_map_plan(plan: MapPlan) -> void:
	map_plan = plan


func register_movement(adapter: MovementAdapter) -> void:
	movement = adapter


func register_job_service(service: JobService) -> void:
	job_service = service


func register_storehouse(building: Storehouse) -> void:
	storehouse = building
