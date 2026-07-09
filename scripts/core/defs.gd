extends Node

## Central enums, groups, and layer names. Do not hardcode these strings elsewhere.

const GROUP_GOBLIN := &"goblin"
const GROUP_FOBLIN := &"foblin"
const GROUP_RESOURCE_NODE := &"resource_node"
const GROUP_BUILDING := &"building"
const GROUP_STOREHOUSE := &"storehouse"
const GROUP_WARREN := &"warren"
const GROUP_CONSTRUCTION := &"construction_site"
const GROUP_FOOD_PRODUCER := &"food_producer"
const GROUP_FORAGER_POST := &"forager_post"
const GROUP_SHRINE := &"shrine"
const GROUP_BURIAL := &"burial_grounds"
const GROUP_ENEMY := &"enemy"
const GROUP_BREEDER := &"breeder_hut"
const GROUP_BARRACKS := &"barracks"
const GROUP_BLACKSMITH := &"blacksmith"
const GROUP_COOK_HUT := &"cook_hut"
const GROUP_SHAMAN_HUT := &"shaman_hut"
const GROUP_HOBGOBLIN_WARRIOR := &"hobgoblin_warrior"
const GROUP_HOBGOBLIN_MAGE := &"hobgoblin_mage"

const LAYER_WORLD := 1
const LAYER_UI := 2

enum ResourceKind {
	GOLD,
	WOOD,
	STONE,
	FOOD,
	MAGIC,
	BONES,
}

enum BuildingKind {
	STOREHOUSE,
	LUMBER_HUT,
	GOLD_MINE,
	QUARRY,
	SLEEPING_PIT,
	WARREN,
	FORAGER_POST,
	MUSHROOM_FARM,
	BREEDER_HUT,
	SHRINE,
	GUARD_POST,
	WATCHTOWER,
	BURIAL_GROUNDS,
	BARRACKS,
	BLACKSMITH,
	COOK_HUT,
	SHAMAN_HUT,
}

enum JobKind {
	IDLE,
	MOVE,
	GATHER,
	DELIVER,
	BUILD,
	FORAGE,
	PRAY,
	GUARD,
	FIGHT,
}

enum WorkerPhase {
	IDLE,
	MOVE,
	WORK,
}

enum NeedKind {
	HUNGER,
	ENERGY,
}

enum EnemyKind {
	BEAST,
	SCOUT,
	MILITIA,
}

enum DemoOutcome {
	NONE,
	WIN,
	LOSS,
}

enum TerrainClass {
	MUD_CLEARING,
	MOSS,
	FOREST_FLOOR,
	ROCKY_SLOPE,
	MUD_MOSSY,
	CLIFF,
	WARREN_GROUND,
}
