extends Node3D

## Isolated Terrain3D compatibility spike — not wired into colony gameplay.
## See docs/technical/TERRAIN3D_HYBRID_MAP_PLAN.md §14.

const DATA_DIR := "res://data/dev/terrain3d_spike/terrain_data"
const HEIGHT_IMAGE_SIZE := 256

@onready var _terrain: Node = $Terrain3D
@onready var _results_label: Label = $UI/ResultsLabel


func _ready() -> void:
	var results := run_checks(_terrain)
	_log_results(results)
	if _results_label:
		_results_label.text = format_results(results)
	if _should_auto_quit():
		if headless_passes(results):
			print(
				"[terrain3d-spike] ok version=%s height=%s normal=%s instancer=%s save=%s collision=%s"
				% [
					str(results.get("version", "")),
					str(results.get("height_query_ok", false)),
					str(results.get("normal_query_ok", false)),
					str(results.get("instancer_assets_ok", false)),
					str(results.get("save_reload_ok", false)),
					str(results.get("collision_ray_ok", false)),
				]
			)
		else:
			push_error("[terrain3d-spike] automated checks failed")
			print(format_results(results))
		var exit_code := 0 if headless_passes(results) else 1
		get_tree().call_deferred("quit", exit_code)


static func _should_auto_quit() -> bool:
	return OS.has_feature("server") or DisplayServer.get_name() == "headless"


static func run_checks(terrain: Node) -> Dictionary:
	var results := {
		"class_exists": ClassDB.class_exists("Terrain3D"),
		"can_instantiate": ClassDB.can_instantiate("Terrain3D"),
		"terrain_ready": terrain != null,
		"data_initialized": false,
		"height_query_ok": false,
		"normal_query_ok": false,
		"slope_degrees": NAN,
		"collision_ray_ok": false,
		"instancer_assets_ok": false,
		"save_reload_ok": false,
		"version": "",
		"errors": PackedStringArray(),
	}

	if not results["class_exists"]:
		results["errors"].append("Terrain3D class missing — GDExtension not loaded")
		return results

	if terrain == null or not terrain.is_class("Terrain3D"):
		results["errors"].append("Terrain3D node is null or wrong type")
		return results

	results["version"] = str(terrain.call("get_version"))
	_setup_minimal_assets(terrain)
	_ensure_terrain_region(terrain, results)

	if not results["data_initialized"]:
		return results

	var sample_pos := Vector3(float(HEIGHT_IMAGE_SIZE) * 0.5, 0.0, float(HEIGHT_IMAGE_SIZE) * 0.5)
	var terrain_data: Object = terrain.get("data")
	var height: float = terrain_data.call("get_height", sample_pos)
	if not is_nan(height):
		results["height_query_ok"] = true
	else:
		results["errors"].append("get_height returned NAN at %s" % str(sample_pos))

	var normal: Vector3 = terrain_data.call("get_normal", sample_pos)
	if normal.length_squared() > 0.01:
		results["normal_query_ok"] = true
		results["slope_degrees"] = rad_to_deg(acos(clampf(normal.dot(Vector3.UP), -1.0, 1.0)))
	else:
		results["errors"].append("get_normal returned zero vector at %s" % str(sample_pos))

	var assets: Object = terrain.get("assets")
	results["instancer_assets_ok"] = assets != null and int(assets.call("get_mesh_count")) > 0

	results["collision_ray_ok"] = _probe_collision(terrain, sample_pos + Vector3(0.0, 50.0, 0.0))
	if not results["collision_ray_ok"]:
		results["errors"].append(
			"Physics raycast did not hit Terrain3D (expected in headless — verify in editor with Visible Collision Shapes)"
		)

	return results


static func format_results(results: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray([
		"Terrain3D compat spike",
		"  class_exists: %s" % str(results.get("class_exists", false)),
		"  version: %s" % str(results.get("version", "")),
		"  height_query_ok: %s" % str(results.get("height_query_ok", false)),
		"  normal_query_ok: %s" % str(results.get("normal_query_ok", false)),
		"  slope_degrees: %s" % str(results.get("slope_degrees", NAN)),
		"  collision_ray_ok: %s" % str(results.get("collision_ray_ok", false)),
		"  instancer_assets_ok: %s" % str(results.get("instancer_assets_ok", false)),
		"  save_reload_ok: %s" % str(results.get("save_reload_ok", false)),
	])
	var errors: Variant = results.get("errors", PackedStringArray())
	for err in errors:
		lines.append("  error: %s" % str(err))
	return "\n".join(lines)


static func headless_passes(results: Dictionary) -> bool:
	if not bool(results.get("class_exists", false)):
		return false
	if not bool(results.get("data_initialized", false)):
		return false
	if not bool(results.get("height_query_ok", false)):
		return false
	if not bool(results.get("normal_query_ok", false)):
		return false
	if not bool(results.get("instancer_assets_ok", false)):
		return false
	if not bool(results.get("save_reload_ok", false)):
		return false
	return true


static func _setup_minimal_assets(terrain: Node) -> void:
	if terrain.get("material") == null:
		terrain.set("material", ClassDB.instantiate("Terrain3DMaterial"))
	if terrain.get("assets") == null:
		var assets: Object = ClassDB.instantiate("Terrain3DAssets")
		var mesh_asset: Object = ClassDB.instantiate("Terrain3DMeshAsset")
		mesh_asset.set("generated_type", 1)
		mesh_asset.set("density", 4.0)
		assets.call("set_mesh_asset", 0, mesh_asset)
		terrain.set("assets", assets)


static func _ensure_terrain_region(terrain: Node, results: Dictionary) -> void:
	var terrain_data: Object = terrain.get("data")
	if terrain_data == null:
		results["errors"].append("Terrain3D.data is null — node must be in scene tree")
		return

	terrain.set("data_directory", DATA_DIR)
	var global_data_path := ProjectSettings.globalize_path(DATA_DIR)
	if DirAccess.dir_exists_absolute(global_data_path):
		terrain_data.call("load_directory", DATA_DIR)
		if int(terrain_data.call("get_region_count")) > 0:
			results["data_initialized"] = true
			return

	var type_max: int = ClassDB.class_get_integer_constant("Terrain3DRegion", "TYPE_MAX")
	var type_height: int = ClassDB.class_get_integer_constant("Terrain3DRegion", "TYPE_HEIGHT")
	var images: Array = []
	images.resize(type_max)
	images[type_height] = _make_test_height_image(HEIGHT_IMAGE_SIZE)
	terrain_data.call("import_images", images, Vector3.ZERO, 0.0, 1.0)
	terrain_data.call("calc_height_range", true)

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path("res://data/dev/terrain3d_spike/terrain_data")
	)
	terrain_data.call("save_directory", DATA_DIR)
	terrain_data.call("load_directory", DATA_DIR)

	results["data_initialized"] = int(terrain_data.call("get_region_count")) > 0
	results["save_reload_ok"] = _verify_save_directory()
	if not results["save_reload_ok"]:
		results["errors"].append("Terrain data directory missing after save: %s" % DATA_DIR)
	if not results["data_initialized"]:
		results["errors"].append("Failed to create or load Terrain3D region data")


static func _make_test_height_image(size: int) -> Image:
	var img := Image.create(size, size, false, Image.FORMAT_RF)
	for y in range(size):
		for x in range(size):
			var dx := (float(x) / float(maxi(size - 1, 1))) - 0.5
			var dz := (float(y) / float(maxi(size - 1, 1))) - 0.5
			var radius_sq := dx * dx + dz * dz
			var height := clampf(0.55 - radius_sq * 2.2, 0.0, 1.0) * 12.0
			img.set_pixel(x, y, Color(height, 0.0, 0.0, 1.0))
	return img


static func _probe_collision(terrain: Node, ray_origin: Vector3) -> bool:
	var world: World3D = terrain.get_world_3d()
	if world == null:
		return false
	var space_state: PhysicsDirectSpaceState3D = world.direct_space_state
	if space_state == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + Vector3(0.0, -200.0, 0.0)
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit: Dictionary = space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider: Object = hit.get("collider", null)
	if collider == null:
		return false
	if collider.is_class("Terrain3D"):
		return true
	if collider is StaticBody3D:
		var parent: Node = (collider as StaticBody3D).get_parent()
		return parent != null and parent.is_class("Terrain3D")
	return false


static func _verify_save_directory() -> bool:
	var global_path := ProjectSettings.globalize_path(DATA_DIR)
	if not DirAccess.dir_exists_absolute(global_path):
		return false
	var dir := DirAccess.open(global_path)
	if dir == null:
		return false
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.begins_with("terrain3d_") and entry.ends_with(".res"):
			dir.list_dir_end()
			return true
		entry = dir.get_next()
	dir.list_dir_end()
	return false


func _log_results(results: Dictionary) -> void:
	var summary := format_results(results)
	if headless_passes(results):
		Log.info("terrain3d_spike", summary)
	else:
		Log.warn("terrain3d_spike", summary)
