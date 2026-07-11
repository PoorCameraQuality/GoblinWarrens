class_name Constants
extends RefCounted

## Grid and simulation tuning. Units documented inline.

const GRID_WIDTH := 350 ## tiles
const GRID_HEIGHT := 350 ## tiles
const TILE_SIZE := 1.0 ## meters; one Godot unit per tile

# Measured from imported Meshy GLBs at scale 1 (see tests/smoke/_measure_visuals.gd).
const VISUAL_MESHY_BUILDING_WIDTH_M := 1.9 ## warren.glb X/Z extent
const VISUAL_MESHY_BUILDING_HEIGHT_M := 0.87 ## warren.glb Y extent (Meshy exports squat meshes)
const VISUAL_MESHY_WATCHTOWER_WIDTH_M := 0.98 ## watchtower.glb X/Z extent (narrower mesh)
const VISUAL_MESHY_HUMANOID_HEIGHT_M := 1.92 ## worker/foblin.glb Y extent
const VISUAL_MESHY_TREE_HEIGHT_M := 1.89 ## tree_birch.glb Y extent
const VISUAL_MESHY_ROCK_SIZE_M := 1.2 ## kaykit/quaternius rock placeholder

## Goblin unit hierarchy: Foblin is shortest; all other goblin units are +25% taller.
const VISUAL_UNIT_FOBLIN_HEIGHT_M := 0.85
const VISUAL_UNIT_GOBLIN_STANDARD_HEIGHT_M := VISUAL_UNIT_FOBLIN_HEIGHT_M * 1.25 ## workers + hobgoblins
const VISUAL_UNIT_ENEMY_HUMAN_HEIGHT_M := 1.8
const VISUAL_UNIT_BEAST_HEIGHT_M := 1.2
## Building hierarchy: Warren is the settlement landmark; Shrine is tallest; all other buildings are half Warren.
const VISUAL_BUILDING_WARREN_FOOTPRINT_M := 8.0 ## 4×4 tile Warren reads ~2× footprint for silhouette
const VISUAL_BUILDING_WARREN_HEIGHT_M := 4.5
const VISUAL_BUILDING_SHRINE_FOOTPRINT_M := 9.0
const VISUAL_BUILDING_SHRINE_HEIGHT_M := 5.2
const VISUAL_BUILDING_STANDARD_FOOTPRINT_M := VISUAL_BUILDING_WARREN_FOOTPRINT_M * 0.5
const VISUAL_BUILDING_STANDARD_HEIGHT_M := VISUAL_BUILDING_WARREN_HEIGHT_M * 0.5
const VISUAL_ENV_TREE_OAK_HEIGHT_M := 3.0
const VISUAL_ENV_TREE_PINE_HEIGHT_M := 4.0
const VISUAL_ENV_ROCK_SIZE_M := 1.5
const VISUAL_RESOURCE_NODE_SIZE_M := 1.2

const BUILDING_WARREN_SCALE := Vector3(
	VISUAL_BUILDING_WARREN_FOOTPRINT_M / VISUAL_MESHY_BUILDING_WIDTH_M,
	VISUAL_BUILDING_WARREN_HEIGHT_M / VISUAL_MESHY_BUILDING_HEIGHT_M,
	VISUAL_BUILDING_WARREN_FOOTPRINT_M / VISUAL_MESHY_BUILDING_WIDTH_M,
)
const BUILDING_SHRINE_SCALE := Vector3(
	VISUAL_BUILDING_SHRINE_FOOTPRINT_M / VISUAL_MESHY_BUILDING_WIDTH_M,
	VISUAL_BUILDING_SHRINE_HEIGHT_M / VISUAL_MESHY_BUILDING_HEIGHT_M,
	VISUAL_BUILDING_SHRINE_FOOTPRINT_M / VISUAL_MESHY_BUILDING_WIDTH_M,
)
const BUILDING_STANDARD_SCALE := Vector3(
	VISUAL_BUILDING_STANDARD_FOOTPRINT_M / VISUAL_MESHY_BUILDING_WIDTH_M,
	VISUAL_BUILDING_STANDARD_HEIGHT_M / VISUAL_MESHY_BUILDING_HEIGHT_M,
	VISUAL_BUILDING_STANDARD_FOOTPRINT_M / VISUAL_MESHY_BUILDING_WIDTH_M,
)
const BUILDING_WATCHTOWER_SCALE := Vector3(
	VISUAL_BUILDING_STANDARD_FOOTPRINT_M / VISUAL_MESHY_WATCHTOWER_WIDTH_M,
	VISUAL_BUILDING_STANDARD_HEIGHT_M / VISUAL_MESHY_BUILDING_HEIGHT_M,
	VISUAL_BUILDING_STANDARD_FOOTPRINT_M / VISUAL_MESHY_WATCHTOWER_WIDTH_M,
)
const FOBLIN_VISUAL_SCALE := Vector3.ONE * (VISUAL_UNIT_FOBLIN_HEIGHT_M / VISUAL_MESHY_HUMANOID_HEIGHT_M)
const GOBLIN_WORKER_VISUAL_SCALE := Vector3.ONE * (
	VISUAL_UNIT_GOBLIN_STANDARD_HEIGHT_M / VISUAL_MESHY_HUMANOID_HEIGHT_M
)
const HOBGOBLIN_VISUAL_SCALE := GOBLIN_WORKER_VISUAL_SCALE
const ENEMY_HUMAN_VISUAL_SCALE := Vector3.ONE * (
	VISUAL_UNIT_ENEMY_HUMAN_HEIGHT_M / VISUAL_MESHY_HUMANOID_HEIGHT_M
)
const ENEMY_BEAST_VISUAL_SCALE := Vector3.ONE * (VISUAL_UNIT_BEAST_HEIGHT_M / VISUAL_MESHY_HUMANOID_HEIGHT_M)
const ENV_TREE_OAK_SCALE := Vector3.ONE * (VISUAL_ENV_TREE_OAK_HEIGHT_M / VISUAL_MESHY_TREE_HEIGHT_M)
const ENV_TREE_PINE_SCALE := Vector3.ONE * (VISUAL_ENV_TREE_PINE_HEIGHT_M / VISUAL_MESHY_TREE_HEIGHT_M)
const ENV_TREE_SCALE := ENV_TREE_OAK_SCALE
const ENV_STUMP_SCALE := Vector3.ONE * 0.65
const ENV_ROCK_SCALE := Vector3.ONE * (VISUAL_ENV_ROCK_SIZE_M / VISUAL_MESHY_ROCK_SIZE_M)
const ENV_MESHY_PROP_SCALE := Vector3.ONE * 0.85
const ENV_QUATERNIUS_SCALE := Vector3(0.9, 0.9, 0.9)
const RESOURCE_MESHY_SCALE := Vector3.ONE * (VISUAL_RESOURCE_NODE_SIZE_M / VISUAL_MESHY_ROCK_SIZE_M)

const GOBLIN_MOVE_SPEED := 3.5 ## tiles per second; LOWPO workers (no walk clip yet)
const FOBLIN_WALK_CYCLE_SEC := 1.033 ## twigskull walk clip length (see tools/inspect_fbx_scene.gd)
const FOBLIN_TILES_PER_WALK_CYCLE := 1.0 ## tuned: one in-place loop ≈ one grid tile
const FOBLIN_MOVE_SPEED := FOBLIN_TILES_PER_WALK_CYCLE / FOBLIN_WALK_CYCLE_SEC ## ~0.97 tiles/s
const UNIT_VISUAL_YAW_OFFSET := 0.0 ## radians; tune if art rig forward axis differs from +Z

const HUNGER_RATE := 1.0 ## points per second; workers prioritize jobs first
const ENERGY_DRAIN_RATE := 0.5 ## points per second
const HUNGER_EAT_THRESHOLD := 95.0 ## eat only when desperate in RTS mode

const INITIAL_FOBLIN_COUNT := 6 ## expendable starters; proper workers come from Breeder Hut
const BASE_HOUSING_CAPACITY := 6 ## goblins without sleeping pits
const HOUSING_PER_SLEEPING_PIT := 4 ## extra capacity per completed pit
const WARREN_HOUSING_BONUS := 2 ## extra cap from the central warren
const BUILDING_RESOURCE_AMOUNT := 400 ## gatherable units spawned by production buildings

const INITIAL_STOREHOUSE_WOOD := 60
const INITIAL_STOREHOUSE_STONE := 25
const INITIAL_STOREHOUSE_GOLD := 0
const INITIAL_FOOD := 55 ## starting rations (roughly 2 upkeep ticks for 6 goblins)

const FOOD_UPKEEP_INTERVAL := 8.0 ## seconds between colony food ticks
const FOOD_PER_GOBLIN_PER_TICK := 2 ## food consumed per goblin per upkeep tick
const FOOD_COLLAPSE_TICKS := 3 ## consecutive failed ticks before food-collapse loss

const POP_BRACKET_COMFORTABLE_MAX := 30 ## population 0–30: no work penalty
const POP_BRACKET_CROWDED_MAX := 50 ## population 31–50: soft penalty
const POP_BRACKET_OVERSTRETCHED_MAX := 75 ## population 51–75: medium penalty
const POP_EFFICIENCY_CROWDED := 0.9 ## −10% gather/build speed
const POP_EFFICIENCY_OVERSTRETCHED := 0.85 ## −15% gather/build speed
const POP_EFFICIENCY_CHAOTIC := 0.75 ## −25% gather/build unless Warren mitigates
const WARREN_LEVEL_CROWDING_MITIGATION := 3 ## Warren L3+ removes chaotic bracket penalty

const MUSHROOM_FOOD_PER_SECOND := 0.5 ## passive food from mushroom farm
const FORAGE_FOOD_PER_ACTION := 4 ## food per forager work tick
const FORAGE_WORK_TIME := 1.5 ## seconds per forage action

const STARVATION_DAMAGE := 4.0 ## HP per second at max starvation
const STARVATION_WORK_SLOW := 0.5 ## work speed multiplier when starving

const GOBLIN_MAX_HP := 30
const GOBLIN_ATTACK_DAMAGE := 5
const FOBLIN_MAX_HP := 15
const FOBLIN_ATTACK_DAMAGE := 3
const FOBLIN_GATHER_MULTIPLIER := 0.5
const FOBLIN_BUILD_MULTIPLIER := 0.4

const ENEMY_ATTACK_RANGE := 1.2 ## meters
const ENEMY_ATTACK_COOLDOWN := 1.2 ## seconds
const BEAST_HP := 25
const BEAST_DAMAGE := 10
const SCOUT_HP := 20
const SCOUT_DAMAGE := 3
const MILITIA_HP := 40
const MILITIA_DAMAGE := 8

const WARREN_MAX_HP := 200
const BUILDING_MAX_HP := 60

const BREEDER_WORKER_SPAWN_INTERVAL := 20.0 ## seconds between goblin worker spawns from Breeder Hut
const PRAY_WORK_TIME := 2.0 ## seconds per prayer action
const PRAY_MAGIC_GAIN := 3 ## magic per prayer
const SHRINE_PASSIVE_MAGIC_PER_SECOND := 0.1

# Barracks — trains hobgoblin warriors on a timer if resources are available.
const BARRACKS_TRAIN_INTERVAL := 30.0 ## seconds between hobgoblin warrior spawns
const BARRACKS_WOOD_COST := 20 ## wood per hobgoblin warrior
const BARRACKS_STONE_COST := 10 ## stone per hobgoblin warrior
const HOBGOBLIN_WARRIOR_HP := 60
const HOBGOBLIN_WARRIOR_ATTACK_DAMAGE := 12

# Blacksmith — passive attack multiplier applied to all goblin melee damage while it stands.
const BLACKSMITH_ATTACK_MULTIPLIER := 1.25

# Cook Hut — passive food generation. Companion to Mushroom Farm.
const COOK_HUT_FOOD_PER_SECOND := 0.4

# Shaman Hut — trains hobgoblin mages and generates passive magic per living mage.
const SHAMAN_TRAIN_INTERVAL := 45.0 ## seconds between hobgoblin mage spawns
const SHAMAN_GOLD_COST := 40 ## gold per hobgoblin mage
const SHAMAN_FOOD_COST := 15 ## food per hobgoblin mage
const HOBGOBLIN_MAGE_HP := 40
const HOBGOBLIN_MAGE_ATTACK_DAMAGE := 8
const HOBGOBLIN_MAGE_PASSIVE_MAGIC_PER_SECOND := 0.15

const REVIVAL_MAGIC_COST := 30
const BLESS_DEFENDER_MAGIC_COST := 20
const BLESS_DEFENDER_DURATION := 30.0 ## seconds
const BLESS_DEFENDER_DAMAGE_MULT := 1.5

const GATHER_TIME := 1.2 ## seconds per gather action at a node
const TREE_WOOD_AMOUNT := 200 ## wood per felled tree (MVP flat rate)
const TREE_FELL_TIME := 45.0 ## seconds for a foblin to down a standing tree
const TREE_FALL_TARGET_ANGLE_DEG := 88.0 ## log resting angle from vertical
const TREE_FALL_IMPULSE := 3.2 ## initial tip speed (rad/s)
const TREE_FALL_GRAVITY_TORQUE := 14.0 ## pendulum pull (m/s² scale)
const TREE_FALL_DAMPING := 2.4 ## angular damping while tipping
const TREE_FALL_SETTLE_SPEED := 0.35 ## rad/s; below this + near target = locked
const BUILDING_PLACE_ROTATE_STEP_DEG := 90.0 ## `[` / `]` while placing
const GATHER_AMOUNT := 5 ## units taken per gather action
const BUILD_WORK_TIME := 0.8 ## seconds of hammering per build tick
const BUILD_PROGRESS_PER_TICK := 0.08 ## construction progress 0–1 per build tick
const CARRY_CAPACITY := 10 ## max units a goblin carries at once

const SECONDS_PER_DAY := 600.0 ## real-time seconds per in-game day (10 minutes)
const DAY_BANNER_DURATION := 3.5 ## seconds center banner stays visible
const THREAT_FLASH_DURATION := 1.2 ## seconds raid/threat screen flash
const THREAT_MARKER_DURATION := 6.0 ## seconds enemy spawn marker visible
const ENEMY_VISUAL_SCALE := 1.0 ## CSG fallback only; rigged enemies use ENEMY_HUMAN_VISUAL_SCALE
const RAID_MILITIA_COUNT := 5
const SCOUT_OBSERVE_TIME := 4.0 ## seconds before scout retreats

const WORLD_NORTH := Vector3(0.0, 0.0, -1.0) ## authored map top; grid Y decreases
const WORLD_SOUTH := Vector3(0.0, 0.0, 1.0) ## authored map bottom; Warren half
const WORLD_EAST := Vector3(1.0, 0.0, 0.0)
const WORLD_WEST := Vector3(-1.0, 0.0, 0.0)
const CAMERA_PAN_SPEED := 48.0 ## meters per second; faster pan on large maps
const CAMERA_EDGE_SCROLL_MARGIN := 18 ## pixels from viewport edge
const CAMERA_PAN_SMOOTHING := 10.0 ## focus lerp rate (higher = snappier)
const CAMERA_ZOOM_SMOOTHING := 12.0 ## orthographic size lerp rate
const CAMERA_ZOOM_WHEEL_FACTOR := 1.08 ## multiplicative wheel step; wheel up zooms in
const CAMERA_MARGIN_M := 8.0 ## meters beyond map edge; keep focus inside dressed border
const CAMERA_YAW_DEG := 90.0 ## camera south of focus; north is up on screen
const CAMERA_USER_PITCH_DEFAULT := -55.0 ## user-facing pitch; negative = look down
const CAMERA_USER_PITCH_MIN := -75.0 ## most overhead (overview)
const CAMERA_USER_PITCH_MAX := -8.0 ## lowest pitch; near horizon for unit/building detail
const CAMERA_YAW_STEP_DEG := 45.0 ## Q/E snap rotation
const CAMERA_ORBIT_YAW_SENS := 0.004 ## radians per pixel, middle-mouse drag
const CAMERA_ORBIT_PITCH_SENS := 0.12 ## degrees per pixel, shift + middle-mouse
const CAMERA_ORTHO_DISTANCE := 250.0 ## fixed pull-back; ortho zoom uses size, not distance
const CAMERA_PERSPECTIVE_FOV := 35.0 ## narrow FOV for inspect mode
const CAMERA_PERSPECTIVE_DISTANCE_DEFAULT := 90.0 ## meters from focus in inspect mode
const CAMERA_PERSPECTIVE_DISTANCE_MIN := 4.0
const CAMERA_PERSPECTIVE_DISTANCE_MAX := 520.0
const CAMERA_PRESET_CLOSE_PITCH := -38.0
const CAMERA_PRESET_DEFAULT_PITCH := -52.0
const CAMERA_PRESET_FAR_PITCH := -58.0
const CAMERA_PRESET_OVERVIEW_PITCH := -68.0
const CAMERA_ORTHO_CLOSE := 16.0 ## closest colony-management zoom (~32 m tall)
const CAMERA_ORTHO_DEFAULT := 26.0 ## launch framing: Warren + nearby resources readable
const CAMERA_ORTHO_FAR := 42.0 ## planning within the camp (~84 m tall)
const CAMERA_ORTHO_PLAY_MAX := 58.0 ## normal mouse-wheel zoom-out cap
const CAMERA_ORTHO_STRATEGIC := 200.0 ## deliberate map overview (F5)
const CAMERA_ORTHO_STRATEGIC_MIN := 150.0
const CAMERA_ORTHO_STRATEGIC_MAX := 240.0
const CAMERA_ORTHO_OVERVIEW := CAMERA_ORTHO_STRATEGIC ## legacy alias
const CAMERA_ORTHO_MIN := CAMERA_ORTHO_CLOSE
const CAMERA_ORTHO_MAX := CAMERA_ORTHO_PLAY_MAX
## Legacy elevation alias (terrain_texture_review.tscn)
const CAMERA_PITCH_DEG := 55.0
## Legacy perspective review scene aliases (terrain_texture_review.tscn)
const CAMERA_ZOOM_MIN := CAMERA_ORTHO_MIN
const CAMERA_ZOOM_MAX := CAMERA_ORTHO_MAX
const CAMERA_ZOOM_STEP := 3.0
const CAMERA_DEFAULT_DISTANCE := 90.0
const PICK_UNIT_SCREEN_RADIUS := 28.0 ## pixels for click-select on units
const DRAG_SELECT_MIN_SIZE := 6.0 ## pixels before drag box counts

const SAVE_PATH := "user://colony_save.tres"

const GOBLIN_NAMES := [
	"Mog", "Snik-Snik", "Grubba", "Zog", "Nix", "Grib", "Skrix", "Plok", "Yarg", "Blek",
]

# Procedural map generation — see docs/procedural-map-plan.md Phase 1
const MAPGEN_DEMO_SEED := 424242
const MAPGEN_HEIGHT_SCALE := 11.0 ## meters; ridge/valley total elevation range (was 4 — subtle)
const MAPGEN_NOISE_BASE_FREQ := 0.028
const MAPGEN_NOISE_HILL_FREQ := 0.018 ## primary ridge axis
const MAPGEN_NOISE_HILL_FREQ_B := 0.021 ## secondary ridge axis for basin carving
const MAPGEN_NOISE_DETAIL_FREQ := 0.35
const MAPGEN_NOISE_HILL_WEIGHT := 0.55
const MAPGEN_NOISE_DETAIL_WEIGHT := 0.18
const MAPGEN_RIDGE_SHARPNESS := 2.2 ## exponent on (1 - |noise|) — higher = sharper mountains
const MAPGEN_EDGE_UPLIFT := 0.92 ## fraction of height_scale added at map border (enclosing hills)
const MAPGEN_VALLEY_FLATTEN_BLEND := 0.68 ## pull basin floors toward local minimum
const MAPGEN_VALLEY_SLOPE_MAX_DEG := 16.0 ## below this reads as valley floor for placement
const MAPGEN_VALLEY_HEIGHT_MAX_NORM := 0.46 ## normalized height ceiling for valley floor score
const MAPGEN_SMOOTHING_PASSES := 1
const MAPGEN_CAMP_FLAT_RADIUS := 12 ## tiles; overridden per map size in MapConfig.default_for_demo()
const MAPGEN_CAMP_BLEND_RADIUS := 22 ## tiles; smoothstep blend to natural height
const MAPGEN_RESOURCE_MIN_RADIUS := 5 ## tiles from warren; keep nodes out of camp footprint
const MAPGEN_RESOURCE_MAX_RADIUS := 52 ## tiles from warren; first expansion ring in valleys
const MAPGEN_REFERENCE_AREA := 32 * 32 ## density reference for prop scatter tuning
const MAPGEN_CLIFF_ANGLE_DEG := 40.0
const MAPGEN_ROCKY_ANGLE_DEG := 20.0
const MAPGEN_FOREST_HEIGHT_TOP := 0.72 ## normalized height threshold; more FOREST_FLOOR tiles
const MAPGEN_LOWLAND_HEIGHT_TOP := 0.30 ## normalized height threshold

# Terrain material UV — see docs/terrain-texture-brief.md §13
const TERRAIN_UV_SCALE_MACRO := 0.05 ## base at default ortho; scaled up when zoomed in
const TERRAIN_UV_SCALE_LEGACY := 0.35 ## ~2.86m repeat; legacy close-up textures
const TERRAIN_UV_ZOOM_BOOST_MAX := 16.0 ## cap close-up tiling vs default ortho zoom

# Generated foliage (visual only — does not affect AStarGrid2D)
const FOLIAGE_CHUNK_SIZE_M := 16.0 ## meters per MultiMesh grass chunk
const FOLIAGE_NEAR_RANGE_M := 70.0 ## full grass detail within this camera distance
const FOLIAGE_FADE_RANGE_M := 120.0 ## hide grass MultiMeshes beyond this
const FOLIAGE_SHORT_MAX_PER_CHUNK := 140 ## textured clump cards per active chunk
const FOLIAGE_TALL_MAX_PER_CHUNK := 24 ## tall reed/clump cards per active chunk
const FOLIAGE_MIN_CHUNK_DENSITY := 0.08 ## skip chunks below this average density
const FOLIAGE_BUILD_RADIUS_CHUNKS := 8 ## only build MultiMeshes near camp at load (rest later)
const FOLIAGE_AMBIENT_MAX_ZONES := 48 ## hard cap on particle ambient zones
const FOLIAGE_FIREFLY_AMOUNT := 36 ## particles per firefly emitter
const FOLIAGE_BUTTERFLY_AMOUNT := 10 ## particles per butterfly emitter
const FOLIAGE_GNAT_AMOUNT := 24 ## particles per gnat emitter
const FOLIAGE_SPORE_AMOUNT := 18 ## particles per spore emitter
