class_name AmbientLifeSpawner
extends Node3D

## Low-count GPUParticles3D zones from FoliagePlan.ambient_zones.
## Enable/disable by distance and time-of-day — do not use amount_ratio for perf.

const _FoliagePlan := preload("res://scripts/world/foliage/foliage_plan.gd")

var _map_plan: MapPlan = null
var _zones: Array = []
var _emitters: Array[GPUParticles3D] = []
var _day_sim = null ## DaySimulation
var _camera: Camera3D = null
var _enabled: bool = true
var _force_night: bool = false
var _refresh_timer: float = 0.0


func build(map_plan: MapPlan, foliage, day_sim, camera: Camera3D) -> void:
	clear()
	_map_plan = map_plan
	_day_sim = day_sim
	_camera = camera
	if foliage == null:
		return
	_zones = foliage.ambient_zones.duplicate(true)
	for zone in _zones:
		var emitter := _make_emitter(zone)
		if emitter == null:
			continue
		add_child(emitter)
		_emitters.append(emitter)
	_refresh_activity()


func clear() -> void:
	for child in get_children():
		child.queue_free()
	_emitters.clear()
	_zones.clear()


func set_enabled(enabled: bool) -> void:
	_enabled = enabled
	visible = enabled
	_refresh_activity()


func set_force_night(enabled: bool) -> void:
	_force_night = enabled
	_refresh_activity()


func zone_count() -> int:
	return _emitters.size()


func _process(delta: float) -> void:
	if not _enabled:
		return
	_refresh_timer += delta
	if _refresh_timer < 0.25:
		return
	_refresh_timer = 0.0
	_refresh_activity()


func _refresh_activity() -> void:
	var tod := _time_of_day_value()
	var cam_pos := Vector3.ZERO
	if _camera != null:
		cam_pos = _camera.global_position
	for emitter in _emitters:
		if emitter == null or not is_instance_valid(emitter):
			continue
		var tod_rule: String = str(emitter.get_meta("tod", "any"))
		var active_tod := _tod_allows(tod_rule, tod)
		var dist_ok := true
		if _camera != null:
			dist_ok = emitter.global_position.distance_to(cam_pos) <= Constants.FOLIAGE_FADE_RANGE_M
		emitter.emitting = _enabled and active_tod and dist_ok
		emitter.visible = emitter.emitting


func _time_of_day_value() -> float:
	if _force_night:
		return 0.85
	if _day_sim != null:
		return clampf(float(_day_sim.day_progress()), 0.0, 1.0)
	return 0.3


func _tod_allows(rule: String, tod: float) -> bool:
	match rule:
		"day":
			return tod < 0.55
		"night":
			return tod >= 0.55 or _force_night
		_:
			return true


func _make_emitter(zone: Dictionary) -> GPUParticles3D:
	var center: Vector2i = zone.get("center", Vector2i.ZERO)
	var radius: float = float(zone.get("radius", 3.0))
	var effect: int = int(zone.get("effect", 0))
	var intensity: float = float(zone.get("intensity", 0.5))
	var tod: String = str(zone.get("time_of_day", "any"))

	var particles := GPUParticles3D.new()
	particles.name = "Ambient_%d_%d_%d" % [effect, center.x, center.y]
	particles.amount = _amount_for(effect)
	particles.lifetime = _lifetime_for(effect)
	particles.explosiveness = 0.0
	particles.randomness = 0.65
	particles.visibility_aabb = AABB(
		Vector3(-radius * 2.0, -1.0, -radius * 2.0),
		Vector3(radius * 4.0, 6.0, radius * 4.0),
	)
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	particles.set_meta("tod", tod)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = radius
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 180.0
	mat.gravity = _gravity_for(effect)
	mat.initial_velocity_min = _speed_for(effect) * 0.6
	mat.initial_velocity_max = _speed_for(effect)
	mat.scale_min = 0.04 * intensity
	mat.scale_max = 0.09 * intensity
	mat.color = _color_for(effect)
	particles.process_material = mat

	var draw := SphereMesh.new()
	draw.radius = 0.05
	draw.height = 0.1
	var draw_mat := StandardMaterial3D.new()
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.albedo_color = _color_for(effect)
	draw_mat.emission_enabled = effect == _FoliagePlan.AmbientEffect.FIREFLIES or effect == _FoliagePlan.AmbientEffect.SPORES
	if draw_mat.emission_enabled:
		draw_mat.emission = _color_for(effect)
		draw_mat.emission_energy_multiplier = 2.2 if effect == _FoliagePlan.AmbientEffect.FIREFLIES else 1.2
	draw.material = draw_mat
	particles.draw_pass_1 = draw

	var y := HeightSampler.sample_cell(_map_plan, center) + 0.6
	particles.position = Vector3(
		(float(center.x) + 0.5) * Constants.TILE_SIZE,
		y,
		(float(center.y) + 0.5) * Constants.TILE_SIZE,
	)
	particles.emitting = false
	return particles


func _amount_for(effect: int) -> int:
	match effect:
		_FoliagePlan.AmbientEffect.BUTTERFLIES:
			return Constants.FOLIAGE_BUTTERFLY_AMOUNT
		_FoliagePlan.AmbientEffect.FIREFLIES:
			return Constants.FOLIAGE_FIREFLY_AMOUNT
		_FoliagePlan.AmbientEffect.GNATS:
			return Constants.FOLIAGE_GNAT_AMOUNT
		_FoliagePlan.AmbientEffect.SPORES:
			return Constants.FOLIAGE_SPORE_AMOUNT
		_:
			return 8


func _lifetime_for(effect: int) -> float:
	match effect:
		_FoliagePlan.AmbientEffect.BUTTERFLIES:
			return 6.0
		_FoliagePlan.AmbientEffect.FIREFLIES:
			return 4.5
		_FoliagePlan.AmbientEffect.GNATS:
			return 2.5
		_FoliagePlan.AmbientEffect.SPORES:
			return 7.0
		_:
			return 3.0


func _speed_for(effect: int) -> float:
	match effect:
		_FoliagePlan.AmbientEffect.BUTTERFLIES:
			return 0.55
		_FoliagePlan.AmbientEffect.FIREFLIES:
			return 0.25
		_FoliagePlan.AmbientEffect.GNATS:
			return 0.4
		_FoliagePlan.AmbientEffect.SPORES:
			return 0.12
		_:
			return 0.3


func _gravity_for(effect: int) -> Vector3:
	match effect:
		_FoliagePlan.AmbientEffect.SPORES:
			return Vector3(0.0, 0.02, 0.0)
		_FoliagePlan.AmbientEffect.FIREFLIES:
			return Vector3(0.0, 0.05, 0.0)
		_:
			return Vector3(0.0, 0.15, 0.0)


func _color_for(effect: int) -> Color:
	match effect:
		_FoliagePlan.AmbientEffect.BUTTERFLIES:
			return Color(0.85, 0.55, 0.25)
		_FoliagePlan.AmbientEffect.FIREFLIES:
			return Color(0.55, 0.95, 0.45) ## sickly yellow-green
		_FoliagePlan.AmbientEffect.GNATS:
			return Color(0.12, 0.12, 0.1)
		_FoliagePlan.AmbientEffect.SPORES:
			return Color(0.55, 0.75, 0.95)
		_:
			return Color.WHITE
