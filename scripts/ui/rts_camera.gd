class_name RtsCamera
extends Camera3D

## Hybrid RTS camera: tactical ortho default, orbit rotation, optional inspect perspective.

enum CameraMode {
	TACTICAL_ORTHO,
	ORBIT_ORTHO,
	INSPECT_PERSPECTIVE,
}

var _rig: Node3D
var _pivot: Node3D
var _mode: CameraMode = CameraMode.TACTICAL_ORTHO
var _focus: Vector3 = Vector3(
	Constants.GRID_WIDTH * Constants.TILE_SIZE * 0.5,
	0.0,
	Constants.GRID_HEIGHT * Constants.TILE_SIZE * 0.5,
)
var _target_focus: Vector3 = _focus
var _target_ortho_size: float = Constants.CAMERA_ORTHO_DEFAULT
var _current_ortho_size: float = Constants.CAMERA_ORTHO_DEFAULT
var _target_perspective_distance: float = Constants.CAMERA_PERSPECTIVE_DISTANCE_DEFAULT
var _current_perspective_distance: float = Constants.CAMERA_PERSPECTIVE_DISTANCE_DEFAULT
var _yaw: float = deg_to_rad(Constants.CAMERA_YAW_DEG)
var _user_pitch_deg: float = Constants.CAMERA_USER_PITCH_DEFAULT
var _orbiting: bool = false


func _ready() -> void:
	_pivot = get_parent() as Node3D
	_rig = _pivot.get_parent() as Node3D if _pivot != null else null
	if _rig == null or _pivot == null:
		Log.warn("RtsCamera: expected RTSCameraRig/Pivot/Camera3D hierarchy", "camera")
	current = true
	near = 0.3
	far = 1200.0
	_target_focus = _focus
	_apply_mode_projection()
	_apply_transform()
	set_process(true)
	set_process_input(false)


## Called from GoblinWarrenColony._input so viewport input reaches the camera reliably.
func handle_input_event(event: InputEvent) -> void:
	if _debug_console_consuming_input():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			_orbiting = mb.pressed
		elif mb.pressed:
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_apply_wheel_zoom(mb.factor)
				get_viewport().set_input_as_handled()
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_apply_wheel_zoom(-mb.factor)
				get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _orbiting:
		var motion := event as InputEventMouseMotion
		_yaw = wrapf(_yaw - motion.relative.x * Constants.CAMERA_ORBIT_YAW_SENS, -PI, PI)
		_user_pitch_deg = clampf(
			_user_pitch_deg - motion.relative.y * Constants.CAMERA_ORBIT_PITCH_SENS,
			Constants.CAMERA_USER_PITCH_MIN,
			Constants.CAMERA_USER_PITCH_MAX,
		)
		_enter_orbit_mode()
		_apply_transform()
	elif event is InputEventKey:
		var key := event as InputEventKey
		if not key.pressed or key.echo:
			return
		match key.keycode:
			KEY_F2:
				set_zoom_preset("close")
				get_viewport().set_input_as_handled()
			KEY_F3:
				set_zoom_preset("default")
				get_viewport().set_input_as_handled()
			KEY_F4:
				set_zoom_preset("far")
				get_viewport().set_input_as_handled()
			KEY_F5:
				set_zoom_preset("overview")
				get_viewport().set_input_as_handled()
			KEY_Q:
				_yaw = wrapf(_yaw - deg_to_rad(Constants.CAMERA_YAW_STEP_DEG), -PI, PI)
				_enter_orbit_mode()
				_apply_transform()
				get_viewport().set_input_as_handled()
			KEY_E:
				_yaw = wrapf(_yaw + deg_to_rad(Constants.CAMERA_YAW_STEP_DEG), -PI, PI)
				_enter_orbit_mode()
				_apply_transform()
				get_viewport().set_input_as_handled()
			KEY_R:
				reset_to_tactical()
				get_viewport().set_input_as_handled()
			KEY_C:
				if OS.is_debug_build():
					toggle_inspect_mode()
					get_viewport().set_input_as_handled()


func terrain_uv_scale() -> float:
	## Use target zoom, not the smoothed current size. World-space UV is `position * scale`;
	## animating scale during scroll makes ground textures appear to slide.
	var base := TerrainPalette.preferred_uv_scale()
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		var dist := maxf(_target_perspective_distance, Constants.CAMERA_PERSPECTIVE_DISTANCE_MIN)
		var boost := clampf(
			Constants.CAMERA_ORTHO_DEFAULT / dist,
			1.0,
			Constants.TERRAIN_UV_ZOOM_BOOST_MAX,
		)
		return base * boost
	var ortho := maxf(_target_ortho_size, Constants.CAMERA_ORTHO_MIN)
	var boost := clampf(
		Constants.CAMERA_ORTHO_DEFAULT / ortho,
		1.0,
		Constants.TERRAIN_UV_ZOOM_BOOST_MAX,
	)
	return base * boost


func _process(delta: float) -> void:
	var pan := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		pan.y += 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		pan.y -= 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		pan.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		pan.x += 1.0
	pan += _edge_scroll_vector()
	if pan != Vector2.ZERO:
		pan = pan.normalized()
		_apply_transform()
		var forward := -global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.0001:
			forward = forward.normalized()
		var right := global_transform.basis.x
		right.y = 0.0
		if right.length_squared() > 0.0001:
			right = right.normalized()
		_target_focus += (right * pan.x + forward * pan.y) * Constants.CAMERA_PAN_SPEED * delta
		_clamp_focus(_target_focus)

	var pan_t := 1.0 - exp(-Constants.CAMERA_PAN_SMOOTHING * delta)
	_focus = _focus.lerp(_target_focus, pan_t)

	var zoom_t := 1.0 - exp(-Constants.CAMERA_ZOOM_SMOOTHING * delta)
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		_current_perspective_distance = lerpf(
			_current_perspective_distance,
			_target_perspective_distance,
			zoom_t,
		)
	else:
		_current_ortho_size = lerpf(_current_ortho_size, _target_ortho_size, zoom_t)
		size = _current_ortho_size
	_apply_transform()


func reset_to_tactical() -> void:
	_mode = CameraMode.TACTICAL_ORTHO
	_yaw = deg_to_rad(Constants.CAMERA_YAW_DEG)
	_user_pitch_deg = Constants.CAMERA_PRESET_DEFAULT_PITCH
	_target_ortho_size = Constants.CAMERA_ORTHO_DEFAULT
	_apply_mode_projection()
	_apply_transform()


func toggle_inspect_mode() -> void:
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		_mode = CameraMode.ORBIT_ORTHO
	else:
		_mode = CameraMode.INSPECT_PERSPECTIVE
		_target_perspective_distance = Constants.CAMERA_PERSPECTIVE_DISTANCE_DEFAULT
	_apply_mode_projection()
	_apply_transform()


func set_zoom_preset(preset: String) -> void:
	match preset:
		"close":
			_target_ortho_size = Constants.CAMERA_ORTHO_CLOSE
			_user_pitch_deg = Constants.CAMERA_PRESET_CLOSE_PITCH
		"default":
			_target_ortho_size = Constants.CAMERA_ORTHO_DEFAULT
			_user_pitch_deg = Constants.CAMERA_PRESET_DEFAULT_PITCH
		"far":
			_target_ortho_size = Constants.CAMERA_ORTHO_FAR
			_user_pitch_deg = Constants.CAMERA_PRESET_FAR_PITCH
		"overview":
			_target_ortho_size = Constants.CAMERA_ORTHO_OVERVIEW
			_user_pitch_deg = Constants.CAMERA_PRESET_OVERVIEW_PITCH
		_:
			return
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		_mode = CameraMode.ORBIT_ORTHO
	_apply_mode_projection()


func dev_print_status() -> String:
	var mouse_world := Vector3.ZERO
	var viewport := get_viewport()
	if viewport != null:
		mouse_world = ground_hit(viewport.get_mouse_position())
	var map_w := Constants.GRID_WIDTH * Constants.TILE_SIZE
	var map_h := Constants.GRID_HEIGHT * Constants.TILE_SIZE
	var visible_est_x := 0.0
	var visible_est_z := 0.0
	if viewport != null and _mode != CameraMode.INSPECT_PERSPECTIVE:
		var vp_size := viewport.get_visible_rect().size
		var aspect := vp_size.x / maxf(vp_size.y, 1.0)
		visible_est_z = _current_ortho_size * 2.0
		visible_est_x = visible_est_z * aspect
	return (
		"camera mode=%s projection=%s user_pitch=%.1f elevation=%.1f yaw=%.1f "
		+ "ortho_size=%.1f target_ortho=%.1f persp_dist=%.1f fov=%.1f "
		+ "focus=%s cam_pos=%s map_bounds=0,0..%.0f,%.0f raycast=ground_plane mouse_world=%s"
		% [
			_mode_name(),
			"perspective" if _mode == CameraMode.INSPECT_PERSPECTIVE else "orthogonal",
			_user_pitch_deg,
			_elevation_deg(),
			_display_yaw_deg(),
			_current_ortho_size,
			_target_ortho_size,
			_current_perspective_distance,
			fov if _mode == CameraMode.INSPECT_PERSPECTIVE else 0.0,
			str(_focus),
			str(global_position),
			map_w,
			map_h,
			str(mouse_world),
		]
	)


func dev_print_presets() -> String:
	return (
		"camera_presets F2_close=size:%.0f pitch:%.0f F3_default=size:%.0f pitch:%.0f "
		+ "F4_far=size:%.0f pitch:%.0f F5_overview=size:%.0f pitch:%.0f "
		+ "reset_R=yaw:%.0f pitch:%.0f size:%.0f inspect_C=fov:%.0f dist:%.0f..%.0f"
		% [
			Constants.CAMERA_ORTHO_CLOSE,
			Constants.CAMERA_PRESET_CLOSE_PITCH,
			Constants.CAMERA_ORTHO_DEFAULT,
			Constants.CAMERA_PRESET_DEFAULT_PITCH,
			Constants.CAMERA_ORTHO_FAR,
			Constants.CAMERA_PRESET_FAR_PITCH,
			Constants.CAMERA_ORTHO_OVERVIEW,
			Constants.CAMERA_PRESET_OVERVIEW_PITCH,
			Constants.CAMERA_YAW_DEG,
			Constants.CAMERA_PRESET_DEFAULT_PITCH,
			Constants.CAMERA_ORTHO_DEFAULT,
			Constants.CAMERA_PERSPECTIVE_FOV,
			Constants.CAMERA_PERSPECTIVE_DISTANCE_MIN,
			Constants.CAMERA_PERSPECTIVE_DISTANCE_MAX,
		]
	)


func debug_hud_line() -> String:
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		return "Cam: persp fov %.0f | pitch %.0f | yaw %.0f | mode inspect" % [
			fov,
			_user_pitch_deg,
			_display_yaw_deg(),
		]
	return "Cam: ortho %.0f | pitch %.0f | yaw %.0f | mode %s" % [
		_current_ortho_size,
		_user_pitch_deg,
		_display_yaw_deg(),
		_mode_name(),
	]


func ground_hit(screen_pos: Vector2) -> Vector3:
	return WorldRay.ground_hit(self, screen_pos)


func _enter_orbit_mode() -> void:
	if _mode == CameraMode.TACTICAL_ORTHO:
		_mode = CameraMode.ORBIT_ORTHO


func _apply_mode_projection() -> void:
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		projection = PROJECTION_PERSPECTIVE
		fov = Constants.CAMERA_PERSPECTIVE_FOV
	else:
		projection = PROJECTION_ORTHOGONAL
		size = _current_ortho_size


func _apply_wheel_zoom(wheel_delta: float) -> void:
	if is_zero_approx(wheel_delta):
		return
	var factor := pow(Constants.CAMERA_ZOOM_WHEEL_FACTOR, -wheel_delta)
	if _mode == CameraMode.INSPECT_PERSPECTIVE:
		_target_perspective_distance = clampf(
			_target_perspective_distance * factor,
			Constants.CAMERA_PERSPECTIVE_DISTANCE_MIN,
			Constants.CAMERA_PERSPECTIVE_DISTANCE_MAX,
		)
	else:
		_target_ortho_size = clampf(
			_target_ortho_size * factor,
			Constants.CAMERA_ORTHO_MIN,
			Constants.CAMERA_ORTHO_MAX,
		)


func _edge_scroll_vector() -> Vector2:
	var viewport := get_viewport()
	if viewport == null:
		return Vector2.ZERO
	var margin: float = Constants.CAMERA_EDGE_SCROLL_MARGIN
	var size_px: Vector2 = viewport.get_visible_rect().size
	var mouse: Vector2 = viewport.get_mouse_position()
	var pan := Vector2.ZERO
	if mouse.x <= margin:
		pan.x -= 1.0
	elif mouse.x >= size_px.x - margin:
		pan.x += 1.0
	if mouse.y <= margin:
		pan.y -= 1.0
	elif mouse.y >= size_px.y - margin:
		pan.y += 1.0
	return pan


func _clamp_focus(point: Vector3) -> void:
	var margin := Constants.CAMERA_MARGIN_M
	var max_x: float = Constants.GRID_WIDTH * Constants.TILE_SIZE
	var max_z: float = Constants.GRID_HEIGHT * Constants.TILE_SIZE
	point.x = clampf(point.x, -margin, max_x + margin)
	point.z = clampf(point.z, -margin, max_z + margin)


func _apply_transform() -> void:
	var elevation := deg_to_rad(_elevation_deg())
	var distance := (
		_current_perspective_distance
		if _mode == CameraMode.INSPECT_PERSPECTIVE
		else Constants.CAMERA_ORTHO_DISTANCE
	)
	var focus := Vector3(_focus.x, 0.0, _focus.z)
	if _rig != null:
		_rig.global_position = focus
	if _pivot != null:
		_pivot.rotation = Vector3.ZERO
		_pivot.rotation.y = _yaw
	var offset := Vector3(
		cos(_yaw) * cos(elevation) * distance,
		sin(elevation) * distance,
		sin(_yaw) * cos(elevation) * distance,
	)
	global_position = focus + offset
	look_at(focus, Vector3.UP)


func _elevation_deg() -> float:
	return clampf(-_user_pitch_deg, -Constants.CAMERA_USER_PITCH_MAX, -Constants.CAMERA_USER_PITCH_MIN)


func _display_yaw_deg() -> float:
	var deg := rad_to_deg(_yaw)
	while deg < 0.0:
		deg += 360.0
	while deg >= 360.0:
		deg -= 360.0
	return deg


func _mode_name() -> String:
	match _mode:
		CameraMode.TACTICAL_ORTHO:
			return "tactical"
		CameraMode.ORBIT_ORTHO:
			return "orbit"
		CameraMode.INSPECT_PERSPECTIVE:
			return "inspect"
		_:
			return "unknown"


func _debug_console_consuming_input() -> bool:
	var layer := get_tree().root.get_node_or_null("DebugConsoleLayer")
	if layer == null:
		return false
	for child in layer.get_children():
		if child is CanvasItem and (child as CanvasItem).visible:
			return true
	return false
