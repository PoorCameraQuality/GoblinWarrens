class_name WindController
extends Node

## Scene-local wind driver. Updates shared global shader uniforms once per frame.
## Not an autoload — parent under Colony/FoliageRoot.

const PARAM_WIND_DIR := &"gw_wind_direction"
const PARAM_WIND_STRENGTH := &"gw_wind_strength"
const PARAM_WIND_GUST := &"gw_wind_gust"
const PARAM_TIME_OF_DAY := &"gw_time_of_day"
const PARAM_WETNESS := &"gw_weather_wetness"

@export var base_strength: float = 0.32
@export var gust_amplitude: float = 0.45
@export var direction_drift_speed: float = 0.07 ## radians / second

var _angle: float = 0.35
var _time_of_day: float = 0.3 ## 0 = day, 1 = night (stub until lighting TOD exists)
var _day_sim = null ## DaySimulation


func setup(day_sim = null) -> void:
	_day_sim = day_sim
	_ensure_globals()
	_push_all()


func set_time_of_day(value: float) -> void:
	_time_of_day = clampf(value, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set(PARAM_TIME_OF_DAY, _time_of_day)


func _ready() -> void:
	_ensure_globals()
	_push_all()


func _process(delta: float) -> void:
	_angle += direction_drift_speed * delta
	var gust := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0011)
	gust = pow(gust, 2.2) * gust_amplitude
	var dir := Vector3(cos(_angle), 0.0, sin(_angle * 0.87 + 0.4)).normalized()
	RenderingServer.global_shader_parameter_set(PARAM_WIND_DIR, dir)
	RenderingServer.global_shader_parameter_set(PARAM_WIND_STRENGTH, base_strength)
	RenderingServer.global_shader_parameter_set(PARAM_WIND_GUST, gust)
	if _day_sim != null and _day_sim.has_method("day_progress"):
		## Map day progress to a soft day/night curve (peak night near day end).
		var progress: float = float(_day_sim.day_progress())
		_time_of_day = clampf(sin(progress * PI) * 0.15 + progress * 0.55, 0.0, 1.0)
	RenderingServer.global_shader_parameter_set(PARAM_TIME_OF_DAY, _time_of_day)


func _ensure_globals() -> void:
	var existing: Array = RenderingServer.global_shader_parameter_get_list()
	_add_if_missing(existing, PARAM_WIND_DIR, RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(1, 0, 0.2))
	_add_if_missing(existing, PARAM_WIND_STRENGTH, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, base_strength)
	_add_if_missing(existing, PARAM_WIND_GUST, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
	_add_if_missing(existing, PARAM_TIME_OF_DAY, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, _time_of_day)
	_add_if_missing(existing, PARAM_WETNESS, RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)


func _add_if_missing(existing: Array, name: StringName, type: int, default_value: Variant) -> void:
	if existing.has(name):
		return
	RenderingServer.global_shader_parameter_add(name, type, default_value)


func _push_all() -> void:
	RenderingServer.global_shader_parameter_set(PARAM_WIND_DIR, Vector3(1, 0, 0.2))
	RenderingServer.global_shader_parameter_set(PARAM_WIND_STRENGTH, base_strength)
	RenderingServer.global_shader_parameter_set(PARAM_WIND_GUST, 0.0)
	RenderingServer.global_shader_parameter_set(PARAM_TIME_OF_DAY, _time_of_day)
	RenderingServer.global_shader_parameter_set(PARAM_WETNESS, 0.0)
