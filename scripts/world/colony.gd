class_name GoblinWarrenColony
extends Node3D

const _EnvironmentDresser := preload("res://scripts/world/environment_dresser.gd")
const _PopulationBrackets := preload("res://scripts/world/population_brackets.gd")
const _MapConfig := preload("res://data/mapgen/map_config.gd")
const _MapGenerator := preload("res://scripts/world/mapgen/map_generator.gd")
const _TerrainClassifier := preload("res://scripts/world/mapgen/terrain_classifier.gd")
const _TerrainMaterialBuilder := preload("res://scripts/world/mapgen/terrain_material.gd")
const _TerrainClassOverlayBuilder := preload("res://scripts/world/mapgen/terrain_class_overlay.gd")
const _TerrainTransitionOverlayBuilder := preload("res://scripts/world/mapgen/terrain_transition_overlay.gd")
const _CompositionOverlayBuilder := preload("res://scripts/world/mapgen/composition_overlay.gd")
const _VisualScaleAudit := preload("res://scripts/dev/visual_scale_audit.gd")
const _MapValidator := preload("res://scripts/world/mapgen/map_validator.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")
const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _GrassFieldRenderer := preload("res://scripts/world/foliage/grass_field_renderer.gd")
const _AmbientLifeSpawner := preload("res://scripts/world/foliage/ambient_life_spawner.gd")
const _WindController := preload("res://scripts/world/foliage/wind_controller.gd")
const _ColonyObservability := preload("res://scripts/debug/colony_observability.gd")
const _MovementGridOverlay := preload("res://scripts/debug/movement_grid_overlay.gd")
const _GoblinPathOverlay := preload("res://scripts/debug/goblin_path_overlay.gd")
const _AuthoredBootstrap := preload("res://scripts/world/map/authored_colony_bootstrap.gd")
const _StarterEconomyRing := preload("res://scripts/world/starter_economy_ring.gd")
const _MapEdgeBarrier := preload("res://scripts/world/map_edge_barrier.gd")
const _WorldSurface := preload("res://scripts/world/world_surface.gd")

const SAVE_SCHEMA_V2 := 2
const MAP_MODE_PROCGEN := "procgen"
const MAP_MODE_AUTHORED := "authored"
const ENV_MAP_MODE := "GC_MAP_MODE"
const ENV_AUTHORED_AUTO_WARREN := "GC_AUTHORED_AUTO_WARREN"
const ENV_AUTHORED_COLONY_SMOKE := "GC_AUTHORED_COLONY_SMOKE"
const ENV_WARREN_PICK := "GC_WARREN_PICK"

## RTS colony loop: workers gather resources, haul to storehouse, and build structures.

const GOBLIN_SCENE := preload("res://scenes/agents/goblin.tscn")
const FOBLIN_SCENE := preload("res://scenes/agents/foblin.tscn")
const ENEMY_SCENE := preload("res://scenes/agents/enemy_unit.tscn")
const RESOURCE_SCENE := preload("res://scenes/world/resource_node.tscn")
const TREE_RESOURCE_SCENE := preload("res://scenes/world/tree_resource.tscn")
const STOREHOUSE_SCENE := preload("res://scenes/buildings/storehouse.tscn")
const BUILDING_SCENE := preload("res://scenes/buildings/building.tscn")
const CONSTRUCTION_SCENE := preload("res://scenes/buildings/construction_site.tscn")

@export var defer_world_setup: bool = false

@onready var _goblins_root: Node3D = $Goblins
@onready var _resources_root: Node3D = $Resources
@onready var _buildings_root: Node3D = $Buildings
@onready var _construction_root: Node3D = $Construction
@onready var _enemies_root: Node3D = $Enemies
@onready var _tick_label: Label = $UI/HUD/TickLabel
@onready var _day_label: Label = $UI/HUD/DayLabel
@onready var _goblin_label: Label = $UI/HUD/GoblinLabel
@onready var _gold_label: Label = $UI/HUD/GoldLabel
@onready var _wood_label: Label = $UI/HUD/WoodLabel
@onready var _stone_label: Label = $UI/HUD/StoneLabel
@onready var _food_label: Label = $UI/HUD/FoodLabel
@onready var _magic_label: Label = $UI/HUD/MagicLabel
@onready var _jobs_label: Label = $UI/HUD/JobsLabel
@onready var _threat_label: Label = $UI/HUD/ThreatLabel
@onready var _selected_label: Label = $UI/HUD/SelectedLabel
@onready var _camera: RtsCamera = $RTSCameraRig/Pivot/Camera3D
@onready var _selection_box: ColorRect = $UI/SelectionBox
@onready var _build_status_label: Label = $UI/HUD/BuildStatusLabel
@onready var _build_panel: HBoxContainer = $UI/BuildPanel
@onready var _build_panel2: HBoxContainer = $UI/BuildPanel2
@onready var _ghost_root: Node3D = $BuildGhostRoot
@onready var _end_summary: EndSummaryPanel = $UI/EndSummary
@onready var _bless_button: Button = $UI/RitualPanel/BlessButton
@onready var _revive_button: Button = $UI/RitualPanel/ReviveButton
@onready var _markers_root: Node3D = $ThreatMarkers

var _movement: MovementAdapter
var _job_service: JobService
var _storehouse: Storehouse
var _warren: Warren
var _stockpile: Stockpile = Stockpile.new()
var _housing_bonus: int = 0
var _selection: SelectionController
var _build_placement: BuildPlacement
var _day_sim: DaySimulation
var _threats: ThreatScheduler
var _food_upkeep: FoodUpkeep = FoodUpkeep.new()
var _stats: ColonyStats = ColonyStats.new()
var _ritual_panel: RitualPanel
var _demo_guide: DemoGuide
var _tick: int = 0
var _save_timer: float = 0.0
var _demo_outcome: Defs.DemoOutcome = Defs.DemoOutcome.NONE
var _food_collapsed: bool = false
var _pending_burials: Array[DeathRecord] = []
var _goblin_name_index: int = 0
var _map_plan: MapPlan = null
var _terrain_material: ShaderMaterial = null
var _class_overlay_active: bool = false
var _transition_overlay_active: bool = false
var _composition_overlay_active: bool = false
var _walkability_overlay_active: bool = false
var _buildability_overlay_active: bool = false
var _goblin_paths_overlay_active: bool = false
var _walkability_overlay: MeshInstance3D = null
var _buildability_overlay: MeshInstance3D = null
var _goblin_path_overlay: Node3D = null
var _beauty_mode: bool = false
var _prop_scatter_stats: Dictionary = {}
var _map_validation: Dictionary = {}
var _composition_overlay_root: Node3D = null
var _foliage_root: Node3D = null
var _grass_renderer = null ## GrassFieldRenderer
var _ambient_life = null ## AmbientLifeSpawner
var _wind_controller = null ## WindController
var _grass_visible: bool = true
var _force_night_ambience: bool = false
var _authored_mode: bool = false
var _terrain3d_root: Node = null
var _pending_strategic_map = null
var _authored_map_root: String = ""
var _authored_map_id: String = ""
var _authored_map_version: int = 0
var _warren_pick_panel: Control = null
var _world_ready: bool = false


func _ready() -> void:
	_movement = MovementAdapter.new(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)
	Services.register_movement(_movement)
	_job_service = JobService.new()
	add_child(_job_service)
	Services.register_job_service(_job_service)
	_day_sim = DaySimulation.new()
	_day_sim.name = "DaySimulation"
	add_child(_day_sim)
	_threats = ThreatScheduler.new()
	_threats.name = "ThreatScheduler"
	add_child(_threats)
	if _should_use_authored_map():
		defer_world_setup = true
	if defer_world_setup:
		if _should_show_warren_pick_panel():
			call_deferred("_open_warren_pick_panel")
		else:
			_begin_authored_world(_default_authored_warren_cell())
		return
	_setup_world()
	_bootstrap_runtime_after_world()


func _resolve_map_mode() -> String:
	var env_mode := OS.get_environment(ENV_MAP_MODE)
	if not env_mode.is_empty():
		return env_mode
	return str(ProjectSettings.get_setting("game/map_mode", MAP_MODE_PROCGEN))


func _resolve_authored_map_root() -> String:
	var env_root := OS.get_environment("GC_AUTHORED_MAP_ROOT")
	if not env_root.is_empty():
		return env_root
	return str(ProjectSettings.get_setting("game/authored_map_root", _AuthoredBootstrap.DEFAULT_MAP_ROOT))


func _should_use_authored_map() -> bool:
	if defer_world_setup:
		return true
	return _resolve_map_mode() == MAP_MODE_AUTHORED


func _default_authored_warren_cell() -> Vector2i:
	return _AuthoredBootstrap.top_warren_cell(_resolve_authored_map_root())


func _should_show_warren_pick_panel() -> bool:
	if OS.get_environment(ENV_WARREN_PICK) == "1":
		return DisplayServer.get_name() != "headless"
	return false


func _should_auto_pick_warren() -> bool:
	if OS.get_environment(ENV_AUTHORED_AUTO_WARREN) == "1":
		return true
	return DisplayServer.get_name() == "headless"


func _open_warren_pick_panel() -> void:
	_warren_pick_panel = get_node_or_null("UI/WarrenPickPanel") as Control
	if _warren_pick_panel == null:
		Log.error("WarrenPickPanel missing on colony scene", "colony")
		get_tree().quit(1)
		return
	_warren_pick_panel.visible = true
	if _warren_pick_panel.has_method("setup"):
		_warren_pick_panel.setup(_resolve_authored_map_root())
	if _warren_pick_panel.has_signal("warren_chosen"):
		if not _warren_pick_panel.warren_chosen.is_connected(_on_warren_pick_chosen):
			_warren_pick_panel.warren_chosen.connect(_on_warren_pick_chosen)


func _on_warren_pick_chosen(origin: Vector2i, _report: Dictionary) -> void:
	if _warren_pick_panel != null:
		_warren_pick_panel.visible = false
	_begin_authored_world(origin)


func _begin_authored_world(warren_cell: Vector2i) -> void:
	var package: Dictionary = _AuthoredBootstrap.build(_resolve_authored_map_root(), warren_cell)
	var error_text: String = apply_authored_world(package)
	if not error_text.is_empty():
		Log.error(error_text, "colony")
		get_tree().call_deferred("quit", 1)
		return
	finish_deferred_startup(package.get("strategic_map"))


func finish_deferred_startup(strategic_map = null) -> void:
	if not defer_world_setup:
		return
	_pending_strategic_map = strategic_map
	_bootstrap_runtime_after_world()


func _bootstrap_runtime_after_world() -> void:
	_job_service.setup(_movement, _storehouse, self)
	if _pending_strategic_map != null:
		_threats.setup(self, _day_sim, _pending_strategic_map)
	else:
		_threats.setup(self, _day_sim)
	_spawn_initial_goblins()
	_ensure_starter_economy_ring()
	_setup_player_controls()
	_setup_demo_guide()
	Bus.warren_destroyed.connect(_on_warren_destroyed)
	Bus.threat_warning.connect(_on_threat_warning)
	if _tick_label != null:
		_tick_label.visible = OS.is_debug_build()
	_update_hud()
	if OS.is_debug_build():
		_update_map_debug_hud()
		if _map_plan != null:
			Log.info(dev_print_mapgen_status(), "mapgen")
		GoblinWarrensDebugRegister.try_register(self)
	set_process_input(true)
	if OS.get_environment(ENV_AUTHORED_COLONY_SMOKE) == "1":
		call_deferred("_authored_colony_smoke_quit")
	_world_ready = true
	_spawn_map_edge_barrier()
	_focus_camera_on_warren()


func _focus_camera_on_warren() -> void:
	if _camera == null or _map_plan == null:
		return
	var warren_def := BuildingCatalog.warren()
	var center_cell := _map_plan.warren_cell + warren_def.footprint / 2
	var world := _movement.grid_to_world(center_cell)
	_camera.focus_colony_view(world.x, world.z)


func _authored_colony_smoke_quit() -> void:
	await get_tree().process_frame
	if _demo_outcome != Defs.DemoOutcome.NONE:
		push_error(
			"[authored-colony-smoke] unexpected demo outcome=%d before quit"
			% int(_demo_outcome)
		)
		get_tree().call_deferred("quit", 1)
		return
	var resource_count: int = _resources_root.get_child_count()
	if resource_count < 10 or _warren == null or _storehouse == null:
		push_error(
			"[authored-colony-smoke] bootstrap incomplete resources=%d"
			% resource_count
		)
		get_tree().call_deferred("quit", 1)
		return
	print(
		"[authored-colony-smoke] ok resources=%d warren=%s raids=%d"
		% [
			resource_count,
			str(_map_plan.warren_cell if _map_plan != null else Vector2i.ZERO),
			int(_pending_strategic_map.stats.get("raid_entry_count", 0))
			if _pending_strategic_map != null
			else 0,
		]
	)
	get_tree().call_deferred("quit", 0)


func apply_authored_world(package: Dictionary) -> String:
	if not _should_use_authored_map():
		return "apply_authored_world requires authored map mode"
	if not bool(package.get("ok", false)):
		return "authored bootstrap failed: %s" % str(package.get("errors", []))
	var grid = package.get("grid")
	var map_plan: MapPlan = package.get("map_plan")
	if grid == null or map_plan == null:
		return "authored bootstrap missing grid or map_plan"
	_authored_mode = true
	_authored_map_root = str(package.get("map_root", _resolve_authored_map_root()))
	var definition = package.get("definition")
	if definition != null:
		_authored_map_id = str(definition.map_id)
		_authored_map_version = int(definition.map_version)
	_map_plan = map_plan
	Services.register_map_plan(_map_plan)
	grid.apply_to_movement(_movement)
	var terrain_error := _apply_authored_terrain(str(package.get("map_root", "")))
	if not terrain_error.is_empty():
		return terrain_error
	_stockpile.amounts[Defs.ResourceKind.GOLD] = Constants.INITIAL_STOREHOUSE_GOLD
	_stockpile.amounts[Defs.ResourceKind.WOOD] = Constants.INITIAL_STOREHOUSE_WOOD
	_stockpile.amounts[Defs.ResourceKind.STONE] = Constants.INITIAL_STOREHOUSE_STONE
	_stockpile.amounts[Defs.ResourceKind.FOOD] = Constants.INITIAL_FOOD
	_warren = Warren.new()
	_warren.setup_warren(_map_plan.warren_cell, BuildingCatalog.warren())
	_buildings_root.add_child(_warren)
	_block_footprint(_warren.grid_cell, _warren.footprint)
	_storehouse = STOREHOUSE_SCENE.instantiate() as Storehouse
	_buildings_root.add_child(_storehouse)
	_storehouse.setup_store(_map_plan.storehouse_cell, null, _stockpile)
	Services.register_storehouse(_storehouse)
	_block_footprint(_storehouse.grid_cell, _storehouse.footprint)
	_apply_prop_placements(_map_plan)
	_apply_foliage(_map_plan)
	_update_map_debug_hud()
	return ""


func _apply_authored_terrain(map_root: String) -> String:
	var ground := get_node_or_null("Ground") as CSGBox3D
	if ground != null:
		ground.visible = false
	var procgen_mesh := get_node_or_null("TerrainMesh") as MeshInstance3D
	if procgen_mesh != null:
		procgen_mesh.visible = false
	if _terrain3d_root != null:
		_terrain3d_root.queue_free()
		_terrain3d_root = null
	if not ClassDB.class_exists("Terrain3D"):
		return "Terrain3D extension missing for authored demo"
	_terrain3d_root = ClassDB.instantiate("Terrain3D") as Node
	_terrain3d_root.name = "AuthoredTerrain3D"
	add_child(_terrain3d_root)
	_terrain3d_root.set("top_level", true)
	_terrain3d_root.set("vertex_spacing", 1.0)
	var Loader = load("res://scripts/world/terrain/authored_terrain3d_loader.gd")
	var report: Dictionary = Loader.ensure_loaded(
		_terrain3d_root,
		map_root,
		Vector2i(_map_plan.width, _map_plan.height),
	)
	if not bool(report.get("ok", false)):
		return "authored terrain load failed: %s" % str(report.get("errors", []))
	Services.register_terrain3d(_terrain3d_root)
	_enable_terrain3d_collision(_terrain3d_root)
	_ensure_world_environment()
	return ""


func _enable_terrain3d_collision(terrain: Node) -> void:
	if terrain == null:
		return
	var collision: Object = terrain.get("collision")
	if collision != null and collision.has_method("set"):
		collision.set("enabled", true)
		collision.set("mode", 0) ## Terrain3DCollision.MODE_DYNAMIC


func _spawn_map_edge_barrier() -> void:
	var root := get_node_or_null("MapEdgeBarrier") as Node3D
	if root == null:
		root = Node3D.new()
		root.name = "MapEdgeBarrier"
		add_child(root)
	for child in root.get_children():
		child.queue_free()
	var width := _map_plan.width if _map_plan != null else Constants.GRID_WIDTH
	var height := _map_plan.height if _map_plan != null else Constants.GRID_HEIGHT
	var placed: int = _MapEdgeBarrier.spawn(root, width, height, 424242)
	if OS.is_debug_build():
		Log.info("map edge barrier placed=%d" % placed, "colony")


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo and key.keycode == KEY_HOME:
			_focus_camera_on_warren()
			get_viewport().set_input_as_handled()
			return
	if _camera != null:
		_camera.handle_input_event(event)


func _sync_terrain_uv_scale() -> void:
	if _terrain_material == null or _camera == null:
		return
	var uv := _camera.terrain_uv_scale()
	if not is_equal_approx(_terrain_material.get_shader_parameter("uv_scale"), uv):
		_terrain_material.set_shader_parameter("uv_scale", uv)


func _setup_player_controls() -> void:
	_build_placement = BuildPlacement.new()
	_build_placement.name = "BuildPlacement"
	add_child(_build_placement)
	_build_placement.setup(
		_camera,
		_movement,
		self,
		_ghost_root,
		_build_status_label,
		BuildingCatalog.player_placeable(),
	)
	_wire_build_buttons()
	_selection = SelectionController.new()
	_selection.name = "SelectionController"
	add_child(_selection)
	_selection.setup(_camera, _movement, _goblins_root, _job_service, _selection_box)
	_selection.set_build_placement(_build_placement)
	_selection.selection_changed.connect(_on_selection_changed)
	_ritual_panel = RitualPanel.new()
	_ritual_panel.name = "RitualPanelController"
	add_child(_ritual_panel)
	_ritual_panel.setup(self, _bless_button)
	if _revive_button != null:
		_revive_button.text = "Revive Goblin (30 magic)"
		_revive_button.pressed.connect(_on_revive_pressed)


func _setup_demo_guide() -> void:
	_demo_guide = DemoGuide.new()
	_demo_guide.name = "DemoGuide"
	$UI.add_child(_demo_guide)
	_demo_guide.setup(self, _day_sim)
	_demo_guide.pulse_banner("Survive 7 days — build food, faith, and defense.")


func is_raid_cleared() -> bool:
	if _threats == null:
		return false
	return _threats.is_raid_cleared()


func _wire_build_buttons() -> void:
	var options: Array[BuildingDef] = BuildingCatalog.player_placeable()
	var panels: Array[HBoxContainer] = [_build_panel, _build_panel2]
	var index := 0
	for panel in panels:
		if panel == null:
			continue
		for child in panel.get_children():
			if not child is Button:
				continue
			if index >= options.size():
				child.visible = false
				continue
			_bind_build_button(child as Button, options[index], index)
			index += 1
	if _build_panel2 == null:
		return
	while index < options.size():
		var extra := Button.new()
		extra.name = "Build%d" % (index + 1)
		_build_panel2.add_child(extra)
		_bind_build_button(extra, options[index], index)
		index += 1


func _bind_build_button(button: Button, def: BuildingDef, index: int) -> void:
	button.visible = true
	button.text = "%s: %s" % [_build_key_label(index), def.display_name]
	button.tooltip_text = _build_cost_tooltip(def)
	if not button.pressed.is_connected(_on_build_button_pressed):
		button.pressed.connect(_on_build_button_pressed.bind(def))


func _build_key_label(index: int) -> String:
	if index < 9:
		return str(index + 1)
	if index == 9:
		return "0"
	return "-"


func _on_build_button_pressed(def: BuildingDef) -> void:
	if _build_placement != null:
		_build_placement.start_placement(def)


func _build_cost_tooltip(def: BuildingDef) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if def.wood_cost > 0:
		parts.append("%d wood" % def.wood_cost)
	if def.stone_cost > 0:
		parts.append("%d stone" % def.stone_cost)
	if def.gold_cost > 0:
		parts.append("%d gold" % def.gold_cost)
	return ", ".join(parts) if not parts.is_empty() else "free"


func can_place_building(origin: Vector2i, def: BuildingDef) -> bool:
	if def == null or _movement == null:
		return false
	if not PlacementValidator.is_footprint_clear(origin, def, _movement):
		return false
	var stock := get_stockpile()
	if stock == null:
		return false
	return stock.can_afford(def.cost_dict())


func try_place_building(origin: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> ConstructionSite:
	if not can_place_building(origin, def):
		return null
	return _start_construction(origin, def, placement_yaw)


func _physics_process(delta: float) -> void:
	if not _world_ready:
		return
	if OS.is_debug_build():
		_update_map_debug_hud()
	if _demo_outcome != Defs.DemoOutcome.NONE:
		return
	_tick += 1
	_day_sim.tick(delta)
	var goblins := _collect_goblins()
	for goblin in goblins:
		goblin.tick_needs(delta)
		goblin.tick_worker(delta, _job_service)
	for child in _enemies_root.get_children():
		if child is EnemyUnit:
			(child as EnemyUnit).tick_combat(delta)
	_tick_food_producers(delta)
	_tick_breeders(delta)
	_tick_trainers(delta)
	_sync_crowding_multipliers()
	if _food_upkeep.tick(delta, _stockpile, goblins):
		_food_collapsed = true
		_finish_demo(Defs.DemoOutcome.LOSS)
	_save_timer += delta
	if _save_timer >= 8.0:
		_save_timer = 0.0
		ColonySave.save(self)
	_process_burials()
	_evaluate_demo()
	if _demo_guide != null:
		_demo_guide.tick_hud()
	_update_hud()
	_sync_terrain_uv_scale()
	if _tick % 60 == 0:
		Bus.tick_advanced.emit(_tick)


func get_stockpile() -> Stockpile:
	return _stockpile


func get_housing_capacity() -> int:
	var cap: int = Constants.BASE_HOUSING_CAPACITY + _housing_bonus
	if _warren != null and is_instance_valid(_warren):
		cap += Constants.WARREN_HOUSING_BONUS
	return cap


func get_warren() -> Warren:
	return _warren


func get_stats() -> ColonyStats:
	return _stats


func get_current_day() -> int:
	return _day_sim.current_day if _day_sim != null else 1


func count_living_goblins() -> int:
	return _collect_goblins().size()


func count_enemies() -> int:
	var count := 0
	for child in _enemies_root.get_children():
		if child is EnemyUnit:
			count += 1
	return count


func get_warren_level() -> int:
	if _warren != null and is_instance_valid(_warren):
		return _warren.level
	return 1


func get_crowding_efficiency_multiplier() -> float:
	return _PopulationBrackets.work_efficiency_multiplier(
		count_living_goblins(),
		get_warren_level()
	)


func get_crowding_hud_line() -> String:
	var pop: int = count_living_goblins()
	var label: String = _PopulationBrackets.bracket_label(pop, get_warren_level())
	var penalty: int = _PopulationBrackets.penalty_percent(pop, get_warren_level())
	if penalty <= 0:
		return "Crowding: %s" % label
	return "Crowding: %s (−%d%% work)" % [label, penalty]


func _sync_crowding_multipliers() -> void:
	var mult: float = get_crowding_efficiency_multiplier()
	for goblin in _collect_goblins():
		goblin.crowding_work_multiplier = mult


func is_food_collapsed() -> bool:
	return _food_collapsed


func has_building_kind(kind: Defs.BuildingKind) -> bool:
	for node in _buildings_root.get_children():
		if node is Building and (node as Building).building_kind == kind:
			return true
	return false


func has_basic_defense() -> bool:
	return has_building_kind(Defs.BuildingKind.GUARD_POST) or has_building_kind(
		Defs.BuildingKind.WATCHTOWER
	)


func get_watchtower_warning_bonus() -> float:
	var bonus: float = 0.0
	for node in _buildings_root.get_children():
		if node is Watchtower:
			bonus += (node as Watchtower).warning_bonus_seconds()
	return bonus


func add_housing_bonus(amount: int) -> void:
	_housing_bonus += amount


func on_building_finished(_kind: Defs.BuildingKind) -> void:
	_stats.record_building()


func cast_bless_defender() -> bool:
	if not has_building_kind(Defs.BuildingKind.SHRINE):
		return false
	if not _stockpile.try_spend(Defs.ResourceKind.MAGIC, Constants.BLESS_DEFENDER_MAGIC_COST):
		return false
	for goblin in _collect_goblins():
		goblin.apply_damage_buff(
			Constants.BLESS_DEFENDER_DURATION,
			Constants.BLESS_DEFENDER_DAMAGE_MULT,
		)
	Bus.ritual_cast.emit("Bless Defender")
	return true


func try_revive_goblin() -> bool:
	if not has_building_kind(Defs.BuildingKind.BURIAL_GROUNDS):
		return false
	if not _stockpile.try_spend(Defs.ResourceKind.MAGIC, Constants.REVIVAL_MAGIC_COST):
		return false
	var records := _stats.revivable_records()
	if records.is_empty():
		return false
	var record: DeathRecord = records[0]
	record.revived = true
	var cell := _find_spawn_cell_near_warren()
	var goblin := GOBLIN_SCENE.instantiate() as Goblin
	goblin.actor_id = record.actor_id
	goblin.display_name = record.display_name
	_goblins_root.add_child(goblin)
	goblin.setup(cell, _movement, self)
	_stats.record_revival(goblin)
	Bus.goblin_revived.emit(goblin)
	return true


## Debug-only helpers for `game/dev/debug_console/`. Gated by `OS.is_debug_build()`.
func dev_skip_day() -> void:
	if not OS.is_debug_build() or _day_sim == null:
		return
	_day_sim.force_advance_day()


func dev_add_resource(kind: Defs.ResourceKind, amount: int) -> void:
	if not OS.is_debug_build() or amount <= 0:
		return
	_stockpile.deposit(kind, amount)


func dev_damage_warren(amount: int) -> void:
	if not OS.is_debug_build() or _warren == null:
		return
	_warren.take_damage(maxi(1, amount))


func dev_heal_warren() -> void:
	if not OS.is_debug_build() or _warren == null:
		return
	_warren.restore_full()


func dev_start_raid() -> void:
	if not OS.is_debug_build() or _threats == null:
		return
	_threats.dev_trigger_raid()


func dev_spawn_beast() -> void:
	if not OS.is_debug_build():
		return
	spawn_enemy(Defs.EnemyKind.BEAST)


func dev_print_camera_status() -> String:
	if not OS.is_debug_build() or _camera == null:
		return "camera status is debug-only"
	return _camera.dev_print_status()


func dev_print_camera_presets() -> String:
	if not OS.is_debug_build() or _camera == null:
		return "camera presets is debug-only"
	return _camera.dev_print_presets()


func dev_print_terrain_material_status() -> String:
	if not OS.is_debug_build():
		return "terrain material status is debug-only"
	var missing: PackedStringArray = PackedStringArray()
	var bound := 0
	for class_id in range(7):
		var terrain_class: Defs.TerrainClass = class_id as Defs.TerrainClass
		var macro_path := TerrainPalette.macro_texture(terrain_class)
		if ResourceLoader.exists(macro_path):
			bound += 1
		else:
			missing.append(macro_path)
	var terrain := get_node_or_null("TerrainMesh") as MeshInstance3D
	var mat_path := ""
	if _terrain_material != null and _terrain_material.shader != null:
		mat_path = str(_terrain_material.shader.resource_path)
	return (
		"terrain_material macro_all=%s bound=%d/7 uv_scale=%.3f macro_mode=%s shader=%s "
		+ "terrain_mesh=%s material_override=%s missing=[%s]"
		% [
			TerrainPalette.all_macro_textures_present(),
			bound,
			TerrainPalette.preferred_uv_scale(),
			TerrainPalette.all_macro_textures_present(),
			mat_path,
			terrain != null,
			terrain != null and terrain.material_override != null,
			", ".join(missing),
		]
	)


func dev_print_map_validation() -> String:
	if not OS.is_debug_build():
		return "map validation is debug-only"
	if _map_validation.is_empty() and _map_plan != null:
		_map_validation = MapValidator.validate(_map_plan, _MapConfig.default_for_demo())
	return MapValidator.format_report(_map_validation)


func dev_print_visual_scale_audit() -> String:
	if not OS.is_debug_build():
		return "visual scale audit is debug-only"
	return _VisualScaleAudit.run()


func dev_print_prop_scatter_status() -> String:
	if not OS.is_debug_build():
		return "prop scatter status is debug-only"
	return _format_prop_scatter_stats()


func dev_print_terrain_blend_status() -> String:
	if not OS.is_debug_build():
		return "terrain blend status is debug-only"
	if _map_plan == null:
		return "terrain_blend map_plan=null"
	var stats: Dictionary = _map_plan.blend_stats
	var blend_enabled := _map_plan.blend_control != null
	var shader_path := ""
	if _terrain_material != null and _terrain_material.shader != null:
		shader_path = str(_terrain_material.shader.resource_path)
	var pair_counts: Dictionary = stats.get("pair_counts", {})
	var pair_parts: PackedStringArray = PackedStringArray()
	for key in pair_counts.keys():
		pair_parts.append("%s=%d" % [str(key), int(pair_counts[key])])
	pair_parts.sort()
	return (
		"terrain_blend enabled=%s control_map=%s size=%dx%d cells_with_secondary=%d "
		+ "transition_width_m=%.1f pairs=[%s] shader=%s noise_modulation=active"
		% [
			blend_enabled,
			"yes" if blend_enabled else "no",
			int(stats.get("width", 0)),
			int(stats.get("height", 0)),
			int(stats.get("cells_with_blend", 0)),
			float(stats.get("blend_width_m", 0.0)),
			", ".join(pair_parts),
			shader_path,
		]
	)


func dev_toggle_transition_overlay() -> String:
	if not OS.is_debug_build():
		return "transition overlay is debug-only"
	var terrain := get_node_or_null("TerrainMesh") as MeshInstance3D
	if terrain == null or _map_plan == null:
		return "terrain mesh not ready"
	_transition_overlay_active = not _transition_overlay_active
	if _transition_overlay_active:
		_class_overlay_active = false
		terrain.material_override = _TerrainTransitionOverlayBuilder.build(_map_plan)
	else:
		terrain.material_override = _terrain_material
	_update_map_debug_hud()
	return "terrain transition overlay ON" if _transition_overlay_active else "terrain transition overlay OFF"


func dev_toggle_class_overlay() -> String:
	if not OS.is_debug_build():
		return "class overlay is debug-only"
	var terrain := get_node_or_null("TerrainMesh") as MeshInstance3D
	if terrain == null or _map_plan == null:
		return "terrain mesh not ready"
	_class_overlay_active = not _class_overlay_active
	if _class_overlay_active:
		_transition_overlay_active = false
		terrain.material_override = _TerrainClassOverlayBuilder.build()
	else:
		terrain.material_override = _terrain_material
	_update_map_debug_hud()
	return "terrain class overlay ON" if _class_overlay_active else "terrain class overlay OFF"


func dev_toggle_composition_overlay() -> String:
	if not OS.is_debug_build():
		return "composition overlay is debug-only"
	if _map_plan == null:
		return "map plan not ready"
	_composition_overlay_active = not _composition_overlay_active
	if _composition_overlay_root != null:
		_composition_overlay_root.queue_free()
		_composition_overlay_root = null
	if _composition_overlay_active:
		_composition_overlay_root = _CompositionOverlayBuilder.build_node(_map_plan)
		add_child(_composition_overlay_root)
	_update_map_debug_hud()
	return (
		"composition overlay ON (raid=%d approach=%d pockets=%d)"
		% [
			_map_plan.main_raid_path_cells.size(),
			_map_plan.approach_corridor_cells.size(),
			_map_plan.resource_pocket_cells.size(),
		]
		if _composition_overlay_active
		else "composition overlay OFF"
	)


func dev_toggle_beauty_mode() -> String:
	if not OS.is_debug_build():
		return "beauty mode is debug-only"
	_beauty_mode = not _beauty_mode
	var ui := get_node_or_null("UI") as CanvasItem
	if ui != null:
		ui.visible = not _beauty_mode
	if _tick_label != null:
		_tick_label.visible = (not _beauty_mode) and OS.is_debug_build()
	if _beauty_mode:
		_class_overlay_active = false
		_transition_overlay_active = false
		_composition_overlay_active = false
		_walkability_overlay_active = false
		_buildability_overlay_active = false
		_goblin_paths_overlay_active = false
		var terrain := get_node_or_null("TerrainMesh") as MeshInstance3D
		if terrain != null:
			terrain.material_override = _terrain_material
		if _composition_overlay_root != null:
			_composition_overlay_root.queue_free()
			_composition_overlay_root = null
		if _walkability_overlay != null:
			_walkability_overlay.queue_free()
			_walkability_overlay = null
		if _buildability_overlay != null:
			_buildability_overlay.queue_free()
			_buildability_overlay = null
		if _goblin_path_overlay != null:
			_goblin_path_overlay.queue_free()
			_goblin_path_overlay = null
	_update_map_debug_hud()
	return "beauty mode ON (HUD hidden)" if _beauty_mode else "beauty mode OFF"


func dev_toggle_grass() -> String:
	if not OS.is_debug_build():
		return "toggle_grass is debug-only"
	_grass_visible = not _grass_visible
	if _grass_renderer != null:
		_grass_renderer.set_grass_visible(_grass_visible)
	if _ambient_life != null:
		_ambient_life.set_enabled(_grass_visible)
	return "grass ON" if _grass_visible else "grass OFF"


func dev_force_night_ambience() -> String:
	if not OS.is_debug_build():
		return "force_night_ambience is debug-only"
	if _ambient_life == null:
		return "ambient life not ready"
	_force_night_ambience = not _force_night_ambience
	_ambient_life.set_force_night(_force_night_ambience)
	return "night ambience FORCED" if _force_night_ambience else "night ambience AUTO"


func dev_collect_goblins() -> Array:
	return _collect_goblins()


func dev_inspect_goblin(query: String = "") -> String:
	if not OS.is_debug_build():
		return "inspect_goblin is debug-only"
	var goblin := _ColonyObservability.find_goblin(_collect_goblins(), query)
	if goblin == null:
		return "Goblin not found for query '%s'." % query
	return _ColonyObservability.format_goblin(
		_ColonyObservability.snapshot_goblin(goblin, _movement)
	)


func dev_inspect_goblins() -> String:
	if not OS.is_debug_build():
		return "inspect_goblins is debug-only"
	return _ColonyObservability.format_all_goblins(_collect_goblins(), _movement)


func dev_inspect_jobs() -> String:
	if not OS.is_debug_build():
		return "inspect_jobs is debug-only"
	return _ColonyObservability.format_job_report(self)


func dev_toggle_walkability_overlay() -> String:
	if not OS.is_debug_build():
		return "toggle_walkability_overlay is debug-only"
	if _movement == null:
		return "movement adapter not ready"
	_walkability_overlay_active = not _walkability_overlay_active
	if _walkability_overlay != null:
		_walkability_overlay.queue_free()
		_walkability_overlay = null
	if _walkability_overlay_active:
		_walkability_overlay = _MovementGridOverlay.new()
		_walkability_overlay.name = "WalkabilityOverlay"
		_walkability_overlay.apply_walkability(_movement)
		add_child(_walkability_overlay)
	_update_map_debug_hud()
	return "walkability overlay ON" if _walkability_overlay_active else "walkability overlay OFF"


func dev_toggle_buildability_overlay() -> String:
	if not OS.is_debug_build():
		return "toggle_buildability_overlay is debug-only"
	if _map_plan == null:
		return "map_plan not ready"
	_buildability_overlay_active = not _buildability_overlay_active
	if _buildability_overlay != null:
		_buildability_overlay.queue_free()
		_buildability_overlay = null
	if _buildability_overlay_active:
		_buildability_overlay = _MovementGridOverlay.new()
		_buildability_overlay.name = "BuildabilityOverlay"
		_buildability_overlay.apply_buildability(_map_plan, 0.18)
		add_child(_buildability_overlay)
	_update_map_debug_hud()
	return "buildability overlay ON" if _buildability_overlay_active else "buildability overlay OFF"


func dev_toggle_goblin_paths() -> String:
	if not OS.is_debug_build():
		return "toggle_goblin_paths is debug-only"
	if _movement == null:
		return "movement adapter not ready"
	_goblin_paths_overlay_active = not _goblin_paths_overlay_active
	if _goblin_path_overlay != null:
		_goblin_path_overlay.queue_free()
		_goblin_path_overlay = null
	if _goblin_paths_overlay_active:
		_goblin_path_overlay = _GoblinPathOverlay.new()
		_goblin_path_overlay.name = "GoblinPathOverlay"
		_goblin_path_overlay.setup(_movement, dev_collect_goblins)
		add_child(_goblin_path_overlay)
		_goblin_path_overlay.set_active(true)
	else:
		if _goblin_path_overlay != null:
			_goblin_path_overlay.set_active(false)
	_update_map_debug_hud()
	return "goblin paths ON" if _goblin_paths_overlay_active else "goblin paths OFF"


func dev_print_mapgen_status() -> String:
	if _map_plan == null:
		return "terrain_mode=none map_plan=null"
	if _authored_mode:
		var scatter_stats: Dictionary = _map_plan.scatter_stats
		var resource_by_kind: Dictionary = scatter_stats.get("resource_by_kind", {})
		return (
			"map_size=%dx%d terrain_mode=authored map_id=%s "
			% [_map_plan.width, _map_plan.height, str(scatter_stats.get("authored", true))]
			+ "warren_cell=%s storehouse_cell=%s "
			% [str(_map_plan.warren_cell), str(_map_plan.storehouse_cell)]
			+ "resource_nodes=%s trees=%d placements=%d"
			% [
				str(resource_by_kind),
				int(scatter_stats.get("tree_count", 0)),
				_map_plan.prop_placements.size(),
			]
		)
	var config := _MapConfig.default_for_demo()
	var vertex_count := _terrain_mesh_vertex_count(_map_plan.mesh)
	var class_counts := _terrain_class_counts()
	var walkable := 0
	var buildable := 0
	for y in range(_map_plan.height):
		for x in range(_map_plan.width):
			var terrain_class: Defs.TerrainClass = _map_plan.tile_classes[y][x]
			if _TerrainClassifier.is_walkable(terrain_class):
				walkable += 1
			if _TerrainClassifier.is_buildable(terrain_class):
				buildable += 1
	var scenery_props := 0
	var scatter_stats: Dictionary = _map_plan.scatter_stats
	for entry in _map_plan.prop_placements:
		if entry == null:
			continue
		if entry.resource_kind < 0:
			scenery_props += 1
	var height_span := _terrain_height_span()
	var macro_mode := TerrainPalette.all_macro_textures_present()
	var resource_by_kind: Dictionary = scatter_stats.get("resource_by_kind", {})
	var reachable_ok := true
	if not _map_validation.is_empty():
		reachable_ok = bool(_map_validation.get("pass", false))
	return (
		"map_size=%dx%d map_seed=%d terrain_mode=procgen_composition "
		% [_map_plan.width, _map_plan.height, config.seed]
		+ "macro_texture_mode=%s uv_scale=%.3f terrain_mesh_vertices=%d height_range_m=%.2f-%.2f "
		% [macro_mode, TerrainPalette.preferred_uv_scale(), vertex_count, height_span.x, height_span.y]
		+ "class_counts=%s prop_count=%d "
		% [str(class_counts), scenery_props]
		+ "trees=%d blocking_props=%d dressing=%d "
		% [
			int(scatter_stats.get("tree_count", 0)),
			int(scatter_stats.get("blocking_prop_count", 0)),
			int(scatter_stats.get("dressing_count", 0)),
		]
		+ "resource_nodes=%s raid_lane_cells=%d approach_cells=%d pockets=%d "
		% [
			str(resource_by_kind),
			int(scatter_stats.get("main_raid_path_cells", _map_plan.main_raid_path_cells.size())),
			int(scatter_stats.get("approach_corridor_cells", _map_plan.approach_corridor_cells.size())),
			int(scatter_stats.get("resource_pocket_count", _map_plan.resource_pocket_cells.size())),
		]
		+ "reachable_required_resources=%s border_props=%d "
		% [reachable_ok, int(scatter_stats.get("border_prop_count", 0))]
		+ "forest_stamps=%d clearing_stamps=%d road_stamps=%d authored=%s "
		% [
			int(scatter_stats.get("forest_stamp_count", 0)),
			int(scatter_stats.get("clearing_stamp_count", 0)),
			int(scatter_stats.get("road_stamp_count", 0)),
			str(_map_plan.authoring_data != null),
		]
		+ "walkable_cell_count=%d buildable_cell_count=%d warren_cell=%s "
		% [walkable, buildable, str(_map_plan.warren_cell)]
		+ _foliage_status_fragment()
	)


func _foliage_status_fragment() -> String:
	var foliage = null if _map_plan == null else _map_plan.foliage_plan
	if foliage == null:
		return "grass_chunks=0 grass_instances=0 ambient_zones={}"
	var stats: Dictionary = foliage.stats
	var active := 0
	if _grass_renderer != null:
		active = _grass_renderer.active_chunk_count()
	return (
		"grass_chunks=%d grass_instances=%d active_grass_chunks=%d grass_visible=%s ambient_zones=%s"
		% [
			int(stats.get("chunk_count", 0)),
			int(stats.get("instance_estimate", 0)),
			active,
			_grass_visible,
			str(stats.get("ambient_by_type", {})),
		]
	)


func _terrain_mesh_vertex_count(mesh: ArrayMesh) -> int:
	if mesh == null:
		return 0
	var total := 0
	for surface_idx in range(mesh.get_surface_count()):
		var arrays: Array = mesh.surface_get_arrays(surface_idx)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		total += verts.size()
	return total


func _terrain_class_counts() -> Dictionary:
	var counts: Dictionary = {}
	if _map_plan == null:
		return counts
	for y in range(_map_plan.height):
		for x in range(_map_plan.width):
			var terrain_class: Defs.TerrainClass = _map_plan.tile_classes[y][x]
			var key := _terrain_class_name(terrain_class)
			counts[key] = int(counts.get(key, 0)) + 1
	return counts


func _terrain_class_name(terrain_class: Defs.TerrainClass) -> String:
	match terrain_class:
		Defs.TerrainClass.MUD_CLEARING:
			return "MUD_CLEARING"
		Defs.TerrainClass.MOSS:
			return "MOSS"
		Defs.TerrainClass.FOREST_FLOOR:
			return "FOREST_FLOOR"
		Defs.TerrainClass.ROCKY_SLOPE:
			return "ROCKY_SLOPE"
		Defs.TerrainClass.MUD_MOSSY:
			return "MUD_MOSSY"
		Defs.TerrainClass.CLIFF:
			return "CLIFF"
		Defs.TerrainClass.WARREN_GROUND:
			return "WARREN_GROUND"
		_:
			return "UNKNOWN"


func _terrain_height_span() -> Vector2:
	if _map_plan == null or _map_plan.heights.is_empty():
		return Vector2.ZERO
	var min_h := INF
	var max_h := -INF
	for value in _map_plan.heights:
		min_h = minf(min_h, value)
		max_h = maxf(max_h, value)
	return Vector2(min_h, max_h)


func _update_map_debug_hud() -> void:
	if not OS.is_debug_build() or _tick_label == null or _map_plan == null:
		return
	_tick_label.visible = true
	var config := _MapConfig.default_for_demo()
	var cam_line := _camera.debug_hud_line() if _camera != null else ""
	var mode_label := "authored" if _authored_mode else "procgen"
	_tick_label.text = "Map %dx%d seed %d | %s%s%s%s%s%s\n%s" % [
		_map_plan.width,
		_map_plan.height,
		config.seed,
		mode_label,
		" | CLASS OVERLAY" if _class_overlay_active else "",
		" | TRANSITION OVERLAY" if _transition_overlay_active else "",
		" | WALK" if _walkability_overlay_active else "",
		" | BUILD" if _buildability_overlay_active else "",
		" | PATHS" if _goblin_paths_overlay_active else "",
		cam_line,
	]


func on_goblin_died(goblin: Goblin) -> void:
	_stats.record_death(goblin, get_current_day())
	if not goblin.is_foblin():
		var record: DeathRecord = _stats.death_records[_stats.death_records.size() - 1]
		_pending_burials.append(record)


func on_enemy_killed(_enemy: EnemyUnit, _source: Node) -> void:
	_stats.record_enemy_kill()
	if _threats != null:
		_threats.notify_enemy_died()


func on_raid_survived() -> void:
	_stats.raids_survived += 1


func try_spawn_goblin_worker_near(building: BreederHut) -> bool:
	if count_living_goblins() >= get_housing_capacity():
		return false
	var cell := _find_adjacent_walkable(building.grid_cell, building.footprint)
	if cell.x < 0:
		return false
	var worker := GOBLIN_SCENE.instantiate() as Goblin
	worker.actor_id = "goblin_%d" % Time.get_ticks_msec()
	_goblins_root.add_child(worker)
	worker.setup(cell, _movement, self)
	Bus.goblin_spawned.emit(worker)
	return true


func spawn_enemy(kind: Defs.EnemyKind, spawn_cell: Vector2i = Vector2i(-1, -1)) -> void:
	var cell := spawn_cell
	if cell.x < 0 or cell.y < 0:
		cell = Vector2i(Constants.GRID_WIDTH - 2, randi_range(2, Constants.GRID_HEIGHT - 3))
	var enemy := ENEMY_SCENE.instantiate() as EnemyUnit
	_enemies_root.add_child(enemy)
	enemy.setup(kind, cell, _movement, self)
	_spawn_threat_marker(cell, kind)
	if _demo_guide != null:
		_demo_guide.pulse_banner(_enemy_spawn_banner(kind))


func _spawn_threat_marker(cell: Vector2i, kind: Defs.EnemyKind) -> void:
	if _markers_root == null:
		return
	var pillar := CSGCylinder3D.new()
	pillar.radius = 0.55
	pillar.height = 3.5
	pillar.position = _movement.grid_to_world(cell) + Vector3(0.0, 1.75, 0.0)
	var mat := StandardMaterial3D.new()
	match kind:
		Defs.EnemyKind.BEAST:
			mat.albedo_color = Color(0.9, 0.35, 0.1)
		Defs.EnemyKind.SCOUT:
			mat.albedo_color = Color(0.95, 0.85, 0.2)
		_:
			mat.albedo_color = Color(0.95, 0.15, 0.15)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color * 0.6
	pillar.material = mat
	_markers_root.add_child(pillar)
	var timer := get_tree().create_timer(Constants.THREAT_MARKER_DURATION)
	timer.timeout.connect(pillar.queue_free)


func _enemy_spawn_banner(kind: Defs.EnemyKind) -> String:
	match kind:
		Defs.EnemyKind.BEAST:
			return "Beast spotted at map edge!"
		Defs.EnemyKind.SCOUT:
			return "Human scout on the ridge!"
		Defs.EnemyKind.MILITIA:
			return "Militia breaching the camp!"
	return "Enemy nearby!"


func spawn_completed_building(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var building := BuildingFactory.create_building_node(def.kind)
	building.setup(cell, def, placement_yaw)
	_buildings_root.add_child(building)


func spawn_completed_storehouse(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var store := STOREHOUSE_SCENE.instantiate() as Storehouse
	store.setup_store(cell, def, _stockpile)
	store.rotation.y = placement_yaw
	_buildings_root.add_child(store)
	if _storehouse == null:
		_storehouse = store
		Services.register_storehouse(store)


func spawn_mushroom_farm(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var farm := MushroomFarm.new()
	farm.setup_farm(cell, def, _stockpile)
	farm.rotation.y = placement_yaw
	_buildings_root.add_child(farm)


func spawn_forager_post(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var post := ForagerPost.new()
	post.setup_post(cell, def, _stockpile)
	post.rotation.y = placement_yaw
	_buildings_root.add_child(post)


func spawn_breeder_hut(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var hut := BreederHut.new()
	hut.setup_breeder(cell, def)
	hut.rotation.y = placement_yaw
	_buildings_root.add_child(hut)


func spawn_shrine(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var shrine := ShrineBuilding.new()
	shrine.setup_shrine(cell, def, _stockpile)
	shrine.rotation.y = placement_yaw
	_buildings_root.add_child(shrine)


func spawn_burial_grounds(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var burial := BurialGrounds.new()
	burial.setup_burial(cell, def, _stockpile)
	burial.rotation.y = placement_yaw
	_buildings_root.add_child(burial)


func spawn_guard_post(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var post := GuardPost.new()
	post.setup_guard(cell, def)
	post.rotation.y = placement_yaw
	_buildings_root.add_child(post)


func spawn_watchtower(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var tower := Watchtower.new()
	tower.setup_tower(cell, def)
	tower.rotation.y = placement_yaw
	_buildings_root.add_child(tower)


func spawn_barracks(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var barracks := Barracks.new()
	barracks.setup_barracks(cell, def, _stockpile)
	barracks.rotation.y = placement_yaw
	_buildings_root.add_child(barracks)


func spawn_blacksmith(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var smith := BlacksmithBuilding.new()
	smith.setup(cell, def, placement_yaw)
	_buildings_root.add_child(smith)


func spawn_cook_hut(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var hut := CookHut.new()
	hut.setup_cook_hut(cell, def, _stockpile)
	hut.rotation.y = placement_yaw
	_buildings_root.add_child(hut)


func spawn_shaman_hut(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> void:
	var hut := ShamanHut.new()
	hut.setup_shaman_hut(cell, def, _stockpile)
	hut.rotation.y = placement_yaw
	_buildings_root.add_child(hut)


func try_spawn_hobgoblin_warrior_near(building: Barracks) -> bool:
	if count_living_goblins() >= get_housing_capacity():
		return false
	var cell := _find_adjacent_walkable(building.grid_cell, building.footprint)
	if cell.x < 0:
		return false
	var warrior := GOBLIN_SCENE.instantiate() as Goblin
	warrior.actor_id = "hobwar_%d" % Time.get_ticks_msec()
	warrior.display_name = "Hobgoblin Warrior"
	warrior.is_hobgoblin_warrior = true
	warrior.is_militia = true
	warrior.max_hp = Constants.HOBGOBLIN_WARRIOR_HP
	warrior.attack_damage = Constants.HOBGOBLIN_WARRIOR_ATTACK_DAMAGE
	_goblins_root.add_child(warrior)
	warrior.setup(cell, _movement, self)
	warrior.add_to_group(Defs.GROUP_HOBGOBLIN_WARRIOR)
	Bus.goblin_spawned.emit(warrior)
	if _demo_guide != null:
		_demo_guide.pulse_banner("Hobgoblin Warrior joins the war party!")
	return true


func try_spawn_hobgoblin_mage_near(building: ShamanHut) -> bool:
	if count_living_goblins() >= get_housing_capacity():
		return false
	var cell := _find_adjacent_walkable(building.grid_cell, building.footprint)
	if cell.x < 0:
		return false
	var mage := GOBLIN_SCENE.instantiate() as Goblin
	mage.actor_id = "hobmage_%d" % Time.get_ticks_msec()
	mage.display_name = "Hobgoblin Mage"
	mage.is_hobgoblin_mage = true
	mage.is_militia = true
	mage.max_hp = Constants.HOBGOBLIN_MAGE_HP
	mage.attack_damage = Constants.HOBGOBLIN_MAGE_ATTACK_DAMAGE
	_goblins_root.add_child(mage)
	mage.setup(cell, _movement, self)
	mage.add_to_group(Defs.GROUP_HOBGOBLIN_MAGE)
	Bus.goblin_spawned.emit(mage)
	if _demo_guide != null:
		_demo_guide.pulse_banner("Hobgoblin Mage answers the call!")
	return true


func spawn_building_gather_node(origin: Vector2i, footprint: Vector2i, kind: Defs.ResourceKind) -> void:
	var cell := _find_adjacent_resource_cell(origin, footprint)
	if cell.x < 0:
		Log.warn("No walkable cell for building gather node (kind=%d)" % kind, "colony")
		return
	_spawn_resource(cell, kind, Constants.BUILDING_RESOURCE_AMOUNT)


func _setup_world() -> void:
	_map_plan = _MapGenerator.build(_MapConfig.default_for_demo())
	Services.register_map_plan(_map_plan)
	_map_validation = MapValidator.validate(_map_plan, _MapConfig.default_for_demo())
	if OS.is_debug_build():
		Log.info(dev_print_map_validation(), "mapgen")
	_movement.set_height_field(
		_map_plan.heights,
		_map_plan.height_point_width,
		_map_plan.height_point_height,
	)
	_apply_procgen_terrain(_map_plan)
	_apply_tile_walkability(_map_plan)
	_stockpile.amounts[Defs.ResourceKind.GOLD] = Constants.INITIAL_STOREHOUSE_GOLD
	_stockpile.amounts[Defs.ResourceKind.WOOD] = Constants.INITIAL_STOREHOUSE_WOOD
	_stockpile.amounts[Defs.ResourceKind.STONE] = Constants.INITIAL_STOREHOUSE_STONE
	_stockpile.amounts[Defs.ResourceKind.FOOD] = Constants.INITIAL_FOOD
	_warren = Warren.new()
	_warren.setup_warren(_map_plan.warren_cell, BuildingCatalog.warren())
	_buildings_root.add_child(_warren)
	_block_footprint(_warren.grid_cell, _warren.footprint)
	_storehouse = STOREHOUSE_SCENE.instantiate() as Storehouse
	_buildings_root.add_child(_storehouse)
	_storehouse.setup_store(_map_plan.storehouse_cell, null, _stockpile)
	Services.register_storehouse(_storehouse)
	_block_footprint(_storehouse.grid_cell, _storehouse.footprint)
	_apply_prop_placements(_map_plan)
	_apply_foliage(_map_plan)
	_apply_debug_showcase()
	_update_map_debug_hud()


func _apply_procgen_terrain(plan: MapPlan) -> void:
	var ground := get_node_or_null("Ground") as CSGBox3D
	if ground != null:
		ground.visible = false
	var terrain := get_node_or_null("TerrainMesh") as MeshInstance3D
	if terrain == null:
		terrain = MeshInstance3D.new()
		terrain.name = "TerrainMesh"
		add_child(terrain)
	terrain.mesh = plan.mesh
	_terrain_material = _TerrainMaterialBuilder.build(plan)
	_class_overlay_active = false
	_transition_overlay_active = false
	terrain.material_override = _terrain_material
	_sync_terrain_uv_scale()
	Services.register_terrain3d(null)
	_ensure_world_environment()


func _apply_foliage(plan: MapPlan) -> void:
	if plan == null or plan.foliage_plan == null:
		return
	_foliage_root = get_node_or_null("FoliageRoot") as Node3D
	if _foliage_root == null:
		_foliage_root = Node3D.new()
		_foliage_root.name = "FoliageRoot"
		add_child(_foliage_root)
	for child in _foliage_root.get_children():
		child.queue_free()

	_wind_controller = _WindController.new()
	_wind_controller.name = "WindController"
	_foliage_root.add_child(_wind_controller)
	_wind_controller.setup(_day_sim)

	_grass_renderer = _GrassFieldRenderer.new()
	_grass_renderer.name = "GrassField"
	_foliage_root.add_child(_grass_renderer)
	_grass_renderer.build(plan, plan.foliage_plan)
	_grass_renderer.set_grass_visible(_grass_visible)

	_ambient_life = _AmbientLifeSpawner.new()
	_ambient_life.name = "AmbientLife"
	_foliage_root.add_child(_ambient_life)
	_ambient_life.build(plan, plan.foliage_plan, _day_sim, _camera)
	_ambient_life.set_enabled(_grass_visible)
	_ambient_life.set_force_night(_force_night_ambience)

	if not Bus.building_completed.is_connected(_on_building_completed_suppress_grass):
		Bus.building_completed.connect(_on_building_completed_suppress_grass)
	if not Bus.construction_started.is_connected(_on_construction_started_suppress_grass):
		Bus.construction_started.connect(_on_construction_started_suppress_grass)


func _on_building_completed_suppress_grass(_kind: int, cell: Vector2i) -> void:
	if _grass_renderer == null:
		return
	_grass_renderer.suppress_footprint(cell, Vector2i(2, 2))


func _on_construction_started_suppress_grass(_kind: int, cell: Vector2i) -> void:
	if _grass_renderer == null:
		return
	_grass_renderer.suppress_footprint(cell, Vector2i(2, 2))


func _apply_prop_placements(plan: MapPlan) -> void:
	var root := get_node_or_null("EnvironmentDressing") as Node3D
	if root == null:
		return
	_reset_prop_scatter_stats(plan)
	for child in root.get_children():
		child.queue_free()
	for entry in plan.prop_placements:
		var placement = entry
		if placement == null:
			continue
		_prop_scatter_stats["requested"] = int(_prop_scatter_stats.get("requested", 0)) + 1
		if placement.resource_kind >= 0:
			_record_prop_path(placement.scene_path, "resource")
			if _VisualCatalog.is_tree_path(placement.scene_path):
				_spawn_tree_resource(placement)
			else:
				_spawn_resource_from_placement(placement)
			_prop_scatter_stats["spawned"] = int(_prop_scatter_stats.get("spawned", 0)) + 1
			_record_prop_spawn(placement)
			continue
		_record_prop_path(placement.scene_path, "scenery")
		if not ResourceLoader.exists(placement.scene_path):
			_record_missing_path(placement.scene_path)
			continue
		var instance := _VisualAttacher.spawn_scenery(
			root,
			placement.scene_path,
			_WorldSurface.snap_world_position(placement.world_pos),
			placement.scale,
		)
		if instance == null:
			_prop_scatter_stats["failed_instantiate"] = int(_prop_scatter_stats.get("failed_instantiate", 0)) + 1
			continue
		instance.rotation.y = placement.rotation_y
		if placement.blocks_movement:
			_movement.set_solid(placement.grid_cell, true)
		_prop_scatter_stats["spawned"] = int(_prop_scatter_stats.get("spawned", 0)) + 1
		_record_prop_spawn(placement)
	if OS.is_debug_build():
		Log.info(dev_print_prop_scatter_status(), "mapgen")


func _reset_prop_scatter_stats(plan: MapPlan) -> void:
	_prop_scatter_stats = {
		"requested": 0,
		"spawned": 0,
		"failed_instantiate": 0,
		"trees_spawned": 0,
		"by_path": {},
		"by_class_spawned": {},
		"missing_paths": [],
		"plan_placements": plan.prop_placements.size(),
		"plan_scatter_stats": plan.scatter_stats.duplicate(true),
	}


func _record_prop_spawn(placement) -> void:
	var class_key := str(int(placement.terrain_class))
	_prop_scatter_stats["by_class_spawned"][class_key] = (
		int(_prop_scatter_stats["by_class_spawned"].get(class_key, 0)) + 1
	)
	if "tree" in placement.scene_path.to_lower():
		_prop_scatter_stats["trees_spawned"] = int(_prop_scatter_stats.get("trees_spawned", 0)) + 1


func _record_prop_path(path: String, category: String) -> void:
	var key := "%s:%s" % [category, path]
	_prop_scatter_stats["by_path"][key] = int(_prop_scatter_stats["by_path"].get(key, 0)) + 1


func _record_missing_path(path: String) -> void:
	var missing: Array = _prop_scatter_stats.get("missing_paths", [])
	if not missing.has(path):
		missing.append(path)
	_prop_scatter_stats["missing_paths"] = missing


func _format_prop_scatter_stats() -> String:
	var missing: Array = _prop_scatter_stats.get("missing_paths", [])
	var missing_preview: PackedStringArray = PackedStringArray()
	for i in range(mini(missing.size(), 10)):
		missing_preview.append(str(missing[i]))
	var plan_stats: Dictionary = _prop_scatter_stats.get("plan_scatter_stats", {})
	return (
		(
			"prop_scatter requested=%d spawned=%d trees_spawned=%d failed_instantiate=%d "
			+ "plan_placements=%d missing_paths=%d plan_tree_requested=%d "
			+ "plan_skipped_density=%d plan_skipped_spacing=%d "
			+ "plan_by_class=%s spawned_by_class=%s first_missing=[%s] by_path=%s"
		)
		% [
			int(_prop_scatter_stats.get("requested", 0)),
			int(_prop_scatter_stats.get("spawned", 0)),
			int(_prop_scatter_stats.get("trees_spawned", 0)),
			int(_prop_scatter_stats.get("failed_instantiate", 0)),
			int(_prop_scatter_stats.get("plan_placements", 0)),
			missing.size(),
			int(plan_stats.get("tree_requested", 0)),
			int(plan_stats.get("skipped_density", 0)),
			int(plan_stats.get("skipped_blocker_spacing", 0)),
			str(plan_stats.get("by_class", {})),
			str(_prop_scatter_stats.get("by_class_spawned", {})),
			", ".join(missing_preview),
			str(_prop_scatter_stats.get("by_path", {})),
		]
	)


func _apply_tile_walkability(plan: MapPlan) -> void:
	for y in range(plan.height):
		for x in range(plan.width):
			var terrain_class: Defs.TerrainClass = plan.tile_classes[y][x]
			if not _TerrainClassifier.is_walkable(terrain_class):
				_movement.set_solid(Vector2i(x, y), true)


func _spawn_demo_resources() -> void:
	## Legacy hand-placed resources — superseded by MapGenerator prop scatter. Not called.
	if _map_plan == null:
		return
	var base := _map_plan.warren_cell
	_spawn_resource_if_walkable(base + Vector2i(-6, -6), Defs.ResourceKind.GOLD, 200)
	_spawn_resource_if_walkable(base + Vector2i(-7, 8), Defs.ResourceKind.WOOD, 150)
	_spawn_resource_if_walkable(base + Vector2i(8, -7), Defs.ResourceKind.WOOD, 150)
	_spawn_resource_if_walkable(base + Vector2i(9, 9), Defs.ResourceKind.STONE, 180)
	_spawn_resource_if_walkable(base + Vector2i(-5, 10), Defs.ResourceKind.STONE, 120)
	_spawn_resource_if_walkable(base + Vector2i(7, 7), Defs.ResourceKind.FOOD, 80)


func _spawn_resource_if_walkable(cell: Vector2i, kind: Defs.ResourceKind, amount: int) -> void:
	if not _movement.is_walkable(cell):
		Log.warn("Skipping resource spawn on blocked tile %s (kind=%d)" % [str(cell), kind], "colony")
		return
	_spawn_resource(cell, kind, amount)


func _apply_debug_showcase() -> void:
	if OS.get_environment("GC_SHOWCASE_TRAINERS") != "1":
		return
	Log.info("Debug showcase active — placing trainers, cheating resources", "colony")
	_stockpile.amounts[Defs.ResourceKind.GOLD] = 500
	_stockpile.amounts[Defs.ResourceKind.WOOD] = 500
	_stockpile.amounts[Defs.ResourceKind.STONE] = 500
	_stockpile.amounts[Defs.ResourceKind.FOOD] = 500
	_stockpile.amounts[Defs.ResourceKind.MAGIC] = 100
	add_housing_bonus(50)
	var base := _map_plan.warren_cell if _map_plan != null else Vector2i(9, 9)
	spawn_barracks(base + Vector2i(-5, -5), BuildingCatalog.barracks())
	spawn_blacksmith(base + Vector2i(-5, 8), BuildingCatalog.blacksmith())
	spawn_cook_hut(base + Vector2i(8, 8), BuildingCatalog.cook_hut())
	spawn_shaman_hut(base + Vector2i(9, -5), BuildingCatalog.shaman_hut())


func _spawn_resource_from_placement(placement) -> void:
	if placement == null:
		return
	if not _movement.is_walkable(placement.grid_cell):
		Log.warn("Skipping resource spawn on blocked tile %s" % str(placement.grid_cell), "colony")
		return
	var node := RESOURCE_SCENE.instantiate() as ResourceNode
	_resources_root.add_child(node)
	node.setup(
		placement.grid_cell,
		placement.resource_kind as Defs.ResourceKind,
		placement.resource_amount,
		str(placement.placement_id),
	)
	_movement.set_solid(placement.grid_cell, true)


func _spawn_resource(cell: Vector2i, kind: Defs.ResourceKind, amount: int, placement_id: String = "") -> void:
	var node := RESOURCE_SCENE.instantiate() as ResourceNode
	_resources_root.add_child(node)
	node.setup(cell, kind, amount, placement_id)
	_movement.set_solid(cell, true)


func _spawn_tree_resource(placement) -> void:
	if placement == null or not _movement.is_walkable(placement.grid_cell):
		Log.warn("Skipping tree spawn on blocked tile %s" % str(placement.grid_cell), "colony")
		return
	var node := TREE_RESOURCE_SCENE.instantiate() as TreeResource
	_resources_root.add_child(node)
	node.setup_tree(
		placement.grid_cell,
		placement.scene_path,
		placement.resource_amount,
		_WorldSurface.snap_world_position(placement.world_pos),
		placement.rotation_y,
		placement.placement_id,
	)
	_movement.set_solid(placement.grid_cell, true)


func _start_construction(cell: Vector2i, def: BuildingDef, placement_yaw: float = 0.0) -> ConstructionSite:
	var stock := get_stockpile()
	if stock == null or not stock.spend(def.cost_dict()):
		Log.warn("Could not afford %s" % def.display_name, "colony")
		return null
	var site := CONSTRUCTION_SCENE.instantiate() as ConstructionSite
	_construction_root.add_child(site)
	site.setup(cell, def, true, placement_yaw)
	site.construction_finished.connect(_on_construction_finished)
	_block_footprint(cell, def.footprint)
	Bus.construction_started.emit(def.kind, cell)
	return site


func _on_construction_finished(site: ConstructionSite, kind: Defs.BuildingKind) -> void:
	var cell: Vector2i = site.grid_cell
	var def: BuildingDef = site.definition
	site.queue_free()
	BuildingFactory.finish_construction(self, cell, def, site.placement_yaw)
	Bus.building_completed.emit(kind, cell)


func try_spawn_starter_resource(cell: Vector2i, kind: Defs.ResourceKind, amount: int) -> bool:
	if not _movement.is_walkable(cell):
		return false
	for node in _resources_root.get_children():
		if node is ResourceNode and (node as ResourceNode).grid_cell == cell:
			return false
	_spawn_resource(cell, kind, amount, "starter/%d_%d" % [cell.x, cell.y])
	return true


func _ensure_starter_economy_ring() -> void:
	if _map_plan == null:
		return
	_StarterEconomyRing.ensure(self, _map_plan.warren_cell)


func _spawn_initial_goblins() -> void:
	var warren_def := BuildingCatalog.warren()
	var origin := (
		_map_plan.warren_cell + Vector2i(-1, -(warren_def.footprint.y + 3))
		if _map_plan != null
		else Vector2i(9, 10)
	)
	for i in range(Constants.INITIAL_FOBLIN_COUNT):
		var foblin := FOBLIN_SCENE.instantiate() as Foblin
		foblin.actor_id = "foblin_%d" % i
		var cell := origin + Vector2i(i % 3, i / 3)
		if not _movement.is_walkable(cell):
			cell = origin + Vector2i(i % 2, i / 2)
		_goblins_root.add_child(foblin)
		foblin.setup_foblin(cell, _movement, self)
		Bus.goblin_spawned.emit(foblin)


func _collect_goblins() -> Array[Goblin]:
	var result: Array[Goblin] = []
	for child in _goblins_root.get_children():
		if child is Goblin and (child as Goblin).is_alive():
			result.append(child as Goblin)
	return result


func _tick_food_producers(delta: float) -> void:
	for node in _buildings_root.get_children():
		if node is MushroomFarm:
			(node as MushroomFarm).tick_production(delta)
		elif node is ShrineBuilding:
			(node as ShrineBuilding).tick_passive(delta)
		elif node is CookHut:
			(node as CookHut).tick_passive(delta)


func _tick_breeders(delta: float) -> void:
	for node in _buildings_root.get_children():
		if node is BreederHut:
			(node as BreederHut).tick_spawn(delta, self)


func _tick_trainers(delta: float) -> void:
	var tree := get_tree()
	for node in _buildings_root.get_children():
		if node is Barracks:
			(node as Barracks).tick_spawn(delta, self)
		elif node is ShamanHut:
			var hut := node as ShamanHut
			hut.tick_spawn(delta, self)
			hut.tick_passive_magic(delta, tree)


func _process_burials() -> void:
	if _pending_burials.is_empty():
		return
	var burial: BurialGrounds = _find_burial_grounds()
	if burial == null:
		return
	while not _pending_burials.is_empty():
		var record: DeathRecord = _pending_burials.pop_front()
		burial.bury_record(record)


func _find_burial_grounds() -> BurialGrounds:
	for node in _buildings_root.get_children():
		if node is BurialGrounds:
			return node as BurialGrounds
	return null


func _find_adjacent_resource_cell(origin: Vector2i, footprint: Vector2i) -> Vector2i:
	return _find_adjacent_walkable(origin, footprint)


func _find_adjacent_walkable(origin: Vector2i, footprint: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [
		origin + Vector2i(footprint.x, 0),
		origin + Vector2i(-1, 0),
		origin + Vector2i(0, footprint.y),
		origin + Vector2i(0, -1),
		origin + Vector2i(footprint.x - 1, footprint.y),
	]
	for cell in candidates:
		if not _movement.is_in_bounds(cell):
			continue
		if not _movement.is_walkable(cell):
			continue
		if _resource_occupies_cell(cell):
			continue
		return cell
	return Vector2i(-1, -1)


func _find_spawn_cell_near_warren() -> Vector2i:
	if _warren != null:
		var cell := _find_adjacent_walkable(_warren.grid_cell, _warren.footprint)
		if cell.x >= 0:
			return cell
	return Vector2i(9, 10)


func _resource_occupies_cell(cell: Vector2i) -> bool:
	for node in _resources_root.get_children():
		if node is ResourceNode and (node as ResourceNode).grid_cell == cell:
			return true
	return false


func _block_footprint(origin: Vector2i, size: Vector2i) -> void:
	_movement.set_footprint_solid(origin, size, true)


func _evaluate_demo() -> void:
	var loss := MvpEvaluator.check_loss(self)
	if loss != Defs.DemoOutcome.NONE:
		_finish_demo(loss)
		return
	var win := MvpEvaluator.check_win(
		self,
		get_current_day(),
		_threats.is_raid_cleared() if _threats != null else false,
	)
	if win != Defs.DemoOutcome.NONE:
		_finish_demo(win)


func _finish_demo(outcome: Defs.DemoOutcome) -> void:
	if not _world_ready:
		return
	if _demo_outcome != Defs.DemoOutcome.NONE:
		return
	_demo_outcome = outcome
	Bus.demo_finished.emit(outcome)
	if _end_summary != null:
		_end_summary.show_summary(self, outcome)


func _on_warren_destroyed() -> void:
	_finish_demo(Defs.DemoOutcome.LOSS)


func _on_threat_warning(message: String) -> void:
	if _threat_label != null:
		_threat_label.text = "⚠ " + message


func _on_revive_pressed() -> void:
	if not try_revive_goblin() and _revive_button != null:
		_revive_button.text = "Revive failed (need burial + magic)"


func _update_hud() -> void:
	if _day_label != null and _demo_guide != null:
		_day_label.text = _demo_guide.format_day_line()
	elif _day_label != null:
		_day_label.text = "Day: %d / 7" % get_current_day()
	_goblin_label.text = "Goblins: %d / %d" % [count_living_goblins(), get_housing_capacity()]
	var stock := get_stockpile()
	if stock != null:
		_gold_label.text = "Gold: %d" % stock.get_amount(Defs.ResourceKind.GOLD)
		_wood_label.text = "Wood: %d" % stock.get_amount(Defs.ResourceKind.WOOD)
		_stone_label.text = "Stone: %d" % stock.get_amount(Defs.ResourceKind.STONE)
		if _food_label != null:
			_food_label.text = "Food: %d" % stock.get_amount(Defs.ResourceKind.FOOD)
		if _magic_label != null:
			_magic_label.text = "Magic: %d" % stock.get_amount(Defs.ResourceKind.MAGIC)
	if _warren != null and is_instance_valid(_warren):
		_jobs_label.text = (
			"Warren HP: %d  |  Enemies: %d  |  %s"
			% [_warren.hp, count_enemies(), get_crowding_hud_line()]
		)
	var build_count := 0
	for node in _construction_root.get_children():
		if node is ConstructionSite and not (node as ConstructionSite).is_complete():
			build_count += 1
	if build_count > 0:
		_jobs_label.text += "  |  Building: %d" % build_count


func _on_selection_changed(selected: Array) -> void:
	if _selected_label == null:
		return
	if _demo_guide != null:
		_selected_label.text = _demo_guide.format_selection(selected)
	else:
		_selected_label.text = "Selected: %d" % selected.size()


func _setup_environment_dressing() -> void:
	## Legacy EnvironmentDresser path — superseded by _apply_prop_placements(). Not called.
	var root := get_node_or_null("EnvironmentDressing") as Node3D
	_EnvironmentDresser.populate(root, Constants.GRID_WIDTH, Constants.GRID_HEIGHT)


func _ensure_world_environment() -> void:
	var world_env := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env == null:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
	var sky := world_env.environment
	if sky == null:
		sky = Environment.new()
		world_env.environment = sky
	## Darker horizon so map edge reads as forest valley, not bright blue void.
	sky.background_mode = Environment.BG_COLOR
	sky.background_color = Color(0.22, 0.28, 0.32)
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(0.48, 0.5, 0.52)
	sky.fog_enabled = true
	sky.fog_light_color = Color(0.28, 0.32, 0.34)
	sky.fog_density = 0.0018
	sky.fog_aerial_perspective = 0.35
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_ensure_horizon_skirt()


func _ensure_horizon_skirt() -> void:
	## Dark ground plane under/around the map to hide sky-colored void at edges.
	if get_node_or_null("HorizonSkirt") != null:
		return
	var skirt := MeshInstance3D.new()
	skirt.name = "HorizonSkirt"
	var plane := PlaneMesh.new()
	var map_m := float(maxi(Constants.GRID_WIDTH, Constants.GRID_HEIGHT)) * Constants.TILE_SIZE
	plane.size = Vector2(map_m * 2.4, map_m * 2.4)
	skirt.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.08, 0.1, 0.09)
	skirt.material_override = mat
	skirt.position = Vector3(map_m * 0.5, -0.4, map_m * 0.5)
	add_child(skirt)


func _apply_ground_visual() -> void:
	_ensure_world_environment()


func capture_save_data() -> ColonySaveData:
	var data := ColonySaveData.new()
	data.schema_version = SAVE_SCHEMA_V2 if _authored_mode else 1
	data.tick = _tick
	for child in _goblins_root.get_children():
		if child is Goblin:
			var goblin := child as Goblin
			data.goblin_cells.append(goblin.grid_cell)
			data.goblin_hunger.append(goblin.hunger)
			data.goblin_energy.append(goblin.energy)
	if _authored_mode:
		data.map_id = _authored_map_id
		data.map_version = _authored_map_version
		if _map_plan != null:
			data.warren_cell = _map_plan.warren_cell
		for child in _resources_root.get_children():
			if child.has_method("export_save_state"):
				data.resource_states.append(child.call("export_save_state"))
	return data


func apply_save_data(data: ColonySaveData) -> Error:
	if data == null:
		return ERR_INVALID_PARAMETER
	if data.schema_version >= SAVE_SCHEMA_V2 and _authored_mode:
		if not data.map_id.is_empty() and data.map_id != _authored_map_id:
			Log.warn(
				"Save map_id=%s does not match loaded map=%s" % [data.map_id, _authored_map_id],
				"save",
			)
		_apply_resource_save_states(data.resource_states)
	_tick = data.tick
	for child in _goblins_root.get_children():
		child.queue_free()
	for i in data.goblin_cells.size():
		var goblin := GOBLIN_SCENE.instantiate() as Goblin
		goblin.actor_id = "goblin_%d" % i
		goblin.hunger = data.goblin_hunger[i] if i < data.goblin_hunger.size() else 20.0
		goblin.energy = data.goblin_energy[i] if i < data.goblin_energy.size() else 100.0
		_goblins_root.add_child(goblin)
		goblin.setup(data.goblin_cells[i], _movement, self)
		Bus.goblin_spawned.emit(goblin)
	return OK


func _apply_resource_save_states(states: Array) -> void:
	var by_id: Dictionary = {}
	for state in states:
		if state is Dictionary:
			var id := str(state.get("placement_id", ""))
			if not id.is_empty():
				by_id[id] = state
	for child in _resources_root.get_children():
		if child is ResourceNode:
			var resource := child as ResourceNode
			if resource.placement_id.is_empty() or not by_id.has(resource.placement_id):
				continue
			resource.apply_save_state(by_id[resource.placement_id])
		elif child is TreeResource:
			var tree := child as TreeResource
			if tree.placement_id.is_empty() or not by_id.has(tree.placement_id):
				continue
			tree.apply_save_state(by_id[tree.placement_id])
