class_name VisualCatalog
extends RefCounted

## Central lookup for visual asset paths.
##
## Constants prefixed with the semantic role (GOBLIN_, RESOURCE_, BUILDING_, ENEMY_, ENV_).
## Goblin Colony canonical Meshy assets live under `game/art/**/goblin_warrens/`.
## Placeholder Quaternius/Kaykit wrappers remain for slots without a Meshy asset yet.
##
## Any Godot-imported `.glb` acts as a PackedScene, so paths can point directly at GLBs
## or at `.tscn` wrappers when we need scale/rotation normalization.

# --- Goblin units (canonical Meshy) ---
const GOBLIN_WORKER := "res://game/art/units/goblins/worker.glb"
const GOBLIN_FOBLIN := "res://game/art/units/goblins/foblin.glb"
const GOBLIN_HOBGOBLIN_WARRIOR := "res://game/art/units/goblins/hobgoblin_warrior.glb"
const GOBLIN_HOBGOBLIN_MAGE := "res://game/art/units/goblins/hobgoblin_mage.glb"

# --- Resource nodes ---
const RESOURCE_WOOD := "res://game/art/props/resources/goblin_warrens/wood_stack.glb"
const RESOURCE_STONE := "res://game/art/props/nature/goblin_warrens/rock_boulder_mossy.glb"
const RESOURCE_STONE_ALT := "res://game/art/props/nature/goblin_warrens/rock_pile.glb"
const RESOURCE_GOLD := "res://game/art/props/resources/goblin_warrens/gold_vein_a.glb"
const RESOURCE_GOLD_ALT := "res://game/art/props/resources/goblin_warrens/gold_vein_b.glb"
const RESOURCE_FOOD := "res://game/art/props/nature/goblin_warrens/mushroom_patch_a.glb"
const RESOURCE_FOOD_ALT := "res://game/art/props/nature/goblin_warrens/mushroom_patch_b.glb"

# --- Buildings (canonical Meshy where available; Quaternius wrappers otherwise) ---
const BUILDING_WARREN := "res://game/art/buildings/goblin_warrens/warren.glb"
const BUILDING_STOREHOUSE := "res://game/art/buildings/goblin_warrens/storehouse.glb"
const BUILDING_SLEEPING_PIT := "res://game/art/buildings/goblin_warrens/sleep_hut.glb"
const BUILDING_BREEDER_HUT := "res://game/art/buildings/goblin_warrens/breeder_hut.glb"
const BUILDING_SHRINE := "res://game/art/buildings/goblin_warrens/shrine.glb"
const BUILDING_WATCHTOWER := "res://game/art/buildings/goblin_warrens/watchtower.glb"
const BUILDING_MUSHROOM_FARM := "res://game/art/buildings/goblin_warrens/mushroom_farm.glb"
const BUILDING_FORAGER_POST := "res://game/art/buildings/goblin_warrens/forager_post.glb"
# Meshy buildings without a matching Defs.BuildingKind yet — visible but not gameplay-wired:
const BUILDING_BARRACKS := "res://game/art/buildings/goblin_warrens/barracks.glb"
const BUILDING_BLACKSMITH := "res://game/art/buildings/goblin_warrens/blacksmith.glb"
const BUILDING_COOK_HUT := "res://game/art/buildings/goblin_warrens/cook_hut.glb"
const BUILDING_SHAMAN_HUT := "res://game/art/buildings/goblin_warrens/shaman_hut.glb"
# Still-placeholder buildings:
const BUILDING_BURIAL_GROUNDS := "res://game/art/buildings/burial_grounds/burial_grounds_visual.tscn"
const BUILDING_GUARD_POST := "res://game/art/buildings/quaternius_parts/medieval_village/guard_post_visual.tscn"
const BUILDING_GENERIC := "res://game/art/buildings/quaternius_parts/medieval_village/generic_hut_visual.tscn"
# Alternate Meshy watchtower (root Desktop dump) — not wired; keep for A/B scale review:
const BUILDING_WATCHTOWER_ALT := "res://game/art/buildings/goblin_warrens/watchtower_alt.glb"

# --- Enemies (Meshy humans; beast still placeholder) ---
# Scale still needs wrapper tuning (Meshy raw → ENEMY_HUMAN_VISUAL_SCALE).
const ENEMY_BEAST := "res://game/art/units/enemies/beast_visual.tscn"
const ENEMY_SCOUT := "res://game/art/units/enemies/goblin_warrens/hooded_vanguard.glb"
const ENEMY_MILITIA := "res://game/art/units/enemies/goblin_warrens/iron_knight.glb"

# --- Environment / nature (canonical Meshy for trees + stumps; placeholder for rest) ---
const ENV_TREE := "res://game/art/props/nature/goblin_warrens/tree_birch.glb"
const ENV_TREE_PINE := "res://game/art/props/nature/goblin_warrens/tree_pine.glb"
const ENV_TREE_PINE_ALT := "res://game/art/props/nature/goblin_warrens/tree_pine_alt.glb"
const ENV_TREE_WILLOW := "res://game/art/props/nature/goblin_warrens/tree_willow.glb"
const ENV_TREE_TALL := "res://game/art/props/nature/goblin_warrens/tree_tall.glb"
const ENV_STUMP_BIRCH := "res://game/art/props/nature/goblin_warrens/stump_birch.glb"
const ENV_STUMP_PINE := "res://game/art/props/nature/goblin_warrens/stump_pine.glb"
const ENV_STUMP_PINE_ALT := "res://game/art/props/nature/goblin_warrens/stump_pine_alt.glb"
const ENV_STUMP_TWIN := "res://game/art/props/nature/goblin_warrens/stump_twin.glb"
const ENV_STUMP_DECORATION := "res://game/art/props/nature/goblin_warrens/stump_decoration.glb"
const ENV_MUSHROOM_PATCH := "res://game/art/props/nature/goblin_warrens/mushroom_patch_a.glb"
const ENV_MUSHROOM_PATCH_ALT := "res://game/art/props/nature/goblin_warrens/mushroom_patch_b.glb"
const ENV_ROCK := "res://game/art/props/nature/goblin_warrens/rock_boulder_mossy.glb"
const ENV_ROCK_PILE := "res://game/art/props/nature/goblin_warrens/rock_pile.glb"
const ENV_ROCK_SPIRE := "res://game/art/props/nature/goblin_warrens/rock_spire_cluster.glb"
const ENV_ROCK_CRAGS := "res://game/art/props/nature/goblin_warrens/rock_triple_crags.glb"
const ENV_RUINS_TERRACE := "res://game/art/props/nature/goblin_warrens/ruins_terraced_stone.glb"
const ENV_RUINS_BONE_FORTRESS := "res://game/art/props/nature/goblin_warrens/ruins_bone_fortress.glb"
const ENV_BORDER_PEAK := "res://game/art/props/nature/goblin_warrens/border_mountains/border_peak.glb"
const ENV_BORDER_SUMMIT := "res://game/art/props/nature/goblin_warrens/border_mountains/border_summit.glb"
const ENV_BORDER_RIDGE_A := "res://game/art/props/nature/goblin_warrens/border_mountains/border_ridge_a.glb"
const ENV_BORDER_RIDGE_B := "res://game/art/props/nature/goblin_warrens/border_mountains/border_ridge_b.glb"
const ENV_BUSH := "res://game/art/props/nature/quaternius/stylized_nature/bush_common_quaternius.tscn"
const ENV_GRASS := "res://game/art/props/nature/quaternius/stylized_nature/grass_short_quaternius.tscn"
const ENV_BARREL := "res://game/art/props/resources/quaternius_fantasy_props/barrel_prop.tscn"
const ENV_CRATE := "res://game/art/props/resources/quaternius_fantasy_props/crate_prop.tscn"

# Cutout foliage textures (alpha PNGs) — used by GrassFieldRenderer MultiMesh cards.
const FOLIAGE_TEX_DIR := "res://game/art/props/nature/goblin_warrens/foliage/"
const FOLIAGE_TEX_GRASS_LUSH := FOLIAGE_TEX_DIR + "grass_clump_lush.png"
const FOLIAGE_TEX_GRASS_MIXED := FOLIAGE_TEX_DIR + "grass_clump_mixed.png"
const FOLIAGE_TEX_GRASS_REED := FOLIAGE_TEX_DIR + "grass_clump_reed.png"
const FOLIAGE_TEX_GRASS_DRY := FOLIAGE_TEX_DIR + "grass_clump_dry.png"
const FOLIAGE_TEX_BUSH_FERN := FOLIAGE_TEX_DIR + "bush_fern_mound.png"
const FOLIAGE_TEX_LITTER_LEAVES := FOLIAGE_TEX_DIR + "litter_dry_leaves.png"
const FOLIAGE_TEX_ROOT_RADIAL := FOLIAGE_TEX_DIR + "root_radial_cluster.png"


static func building_visual_scale(kind: Defs.BuildingKind, path: String = "") -> Vector3:
	match kind:
		Defs.BuildingKind.WARREN:
			return Constants.BUILDING_WARREN_SCALE
		Defs.BuildingKind.SHRINE:
			return Constants.BUILDING_SHRINE_SCALE
		Defs.BuildingKind.WATCHTOWER:
			return Constants.BUILDING_WATCHTOWER_SCALE
		Defs.BuildingKind.GUARD_POST, Defs.BuildingKind.BURIAL_GROUNDS:
			return Constants.BUILDING_STANDARD_SCALE
		_:
			return Constants.BUILDING_STANDARD_SCALE


static func unit_visual_scale(is_foblin: bool, is_hobgoblin_warrior: bool, is_hobgoblin_mage: bool) -> Vector3:
	if is_foblin:
		return Constants.FOBLIN_VISUAL_SCALE
	if is_hobgoblin_warrior or is_hobgoblin_mage:
		return Constants.HOBGOBLIN_VISUAL_SCALE
	return Constants.GOBLIN_WORKER_VISUAL_SCALE


static func resource_visual_scale(path: String) -> Vector3:
	if path.ends_with(".glb"):
		return Constants.RESOURCE_MESHY_SCALE
	return Vector3.ONE


static func env_visual_scale(path: String) -> Vector3:
	var lowered := path.to_lower()
	if "tree_pine" in lowered or "tree_tall" in lowered:
		return Constants.ENV_TREE_PINE_SCALE
	if "tree" in lowered:
		return Constants.ENV_TREE_OAK_SCALE
	if "stump" in lowered:
		return Constants.ENV_STUMP_SCALE
	if "rock" in lowered:
		return Constants.ENV_ROCK_SCALE
	if path.ends_with(".glb"):
		return Constants.ENV_MESHY_PROP_SCALE
	return Constants.ENV_QUATERNIUS_SCALE


static func enemy_visual_scale(kind: Defs.EnemyKind) -> Vector3:
	match kind:
		Defs.EnemyKind.SCOUT, Defs.EnemyKind.MILITIA:
			return Constants.ENEMY_HUMAN_VISUAL_SCALE
		Defs.EnemyKind.BEAST:
			return Constants.ENEMY_BEAST_VISUAL_SCALE
		_:
			return Vector3.ONE


static func building_wrapper(kind: Defs.BuildingKind) -> String:
	match kind:
		Defs.BuildingKind.WARREN:
			return BUILDING_WARREN
		Defs.BuildingKind.STOREHOUSE:
			return BUILDING_STOREHOUSE
		Defs.BuildingKind.SLEEPING_PIT:
			return BUILDING_SLEEPING_PIT
		Defs.BuildingKind.MUSHROOM_FARM:
			return BUILDING_MUSHROOM_FARM
		Defs.BuildingKind.FORAGER_POST:
			return BUILDING_FORAGER_POST
		Defs.BuildingKind.BREEDER_HUT:
			return BUILDING_BREEDER_HUT
		Defs.BuildingKind.SHRINE:
			return BUILDING_SHRINE
		Defs.BuildingKind.BURIAL_GROUNDS:
			return BUILDING_BURIAL_GROUNDS
		Defs.BuildingKind.GUARD_POST:
			return BUILDING_GUARD_POST
		Defs.BuildingKind.WATCHTOWER:
			return BUILDING_WATCHTOWER
		Defs.BuildingKind.BARRACKS:
			return BUILDING_BARRACKS
		Defs.BuildingKind.BLACKSMITH:
			return BUILDING_BLACKSMITH
		Defs.BuildingKind.COOK_HUT:
			return BUILDING_COOK_HUT
		Defs.BuildingKind.SHAMAN_HUT:
			return BUILDING_SHAMAN_HUT
		_:
			return BUILDING_GENERIC


static func resource_wrapper(kind: Defs.ResourceKind) -> String:
	match kind:
		Defs.ResourceKind.WOOD:
			return RESOURCE_WOOD
		Defs.ResourceKind.STONE:
			return RESOURCE_STONE
		Defs.ResourceKind.GOLD:
			return RESOURCE_GOLD
		Defs.ResourceKind.FOOD:
			return RESOURCE_FOOD
		_:
			return ""


static func is_tree_path(path: String) -> bool:
	return "tree" in path.to_lower() and "stump" not in path.to_lower()


static func random_tree_path(rng = null) -> String:
	## Accepts RandomNumberGenerator or MapRng (both expose randi_range).
	var choices: Array[String] = [
		ENV_TREE,
		ENV_TREE_PINE,
		ENV_TREE_PINE_ALT,
		ENV_TREE_WILLOW,
		ENV_TREE_TALL,
	]
	if rng != null:
		return choices[rng.randi_range(0, choices.size() - 1)]
	return choices[randi() % choices.size()]


static func random_rock_path(rng = null) -> String:
	## Accepts RandomNumberGenerator or MapRng (both expose randi_range).
	var choices: Array[String] = [
		ENV_ROCK,
		ENV_ROCK_PILE,
		ENV_ROCK_SPIRE,
		ENV_ROCK_CRAGS,
	]
	if rng != null:
		return choices[rng.randi_range(0, choices.size() - 1)]
	return choices[randi() % choices.size()]


static func stump_for_tree(tree_path: String) -> String:
	## Meshy stumps use the opposite species name from the tree mesh.
	var lowered := tree_path.to_lower()
	if "tree_birch" in lowered:
		return ENV_STUMP_PINE
	if "tree_pine_alt" in lowered:
		return ENV_STUMP_TWIN
	if "tree_pine" in lowered:
		return ENV_STUMP_BIRCH
	if "tree_willow" in lowered:
		return ENV_STUMP_PINE_ALT
	if "tree_tall" in lowered:
		return ENV_STUMP_DECORATION
	return ENV_STUMP_BIRCH


static func enemy_wrapper(kind: Defs.EnemyKind) -> String:
	match kind:
		Defs.EnemyKind.BEAST:
			return ENEMY_BEAST
		Defs.EnemyKind.SCOUT:
			return ENEMY_SCOUT
		Defs.EnemyKind.MILITIA:
			return ENEMY_MILITIA
		_:
			return ""


static func border_mountain_paths() -> Array[String]:
	return [
		ENV_BORDER_PEAK,
		ENV_BORDER_SUMMIT,
		ENV_BORDER_RIDGE_A,
		ENV_BORDER_RIDGE_B,
	]
