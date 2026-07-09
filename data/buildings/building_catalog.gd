class_name BuildingCatalog
extends RefCounted

## Factory for building definition resources.

static func storehouse() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.STOREHOUSE
	def.display_name = "Storehouse"
	def.build_time = 0.0
	def.footprint = Vector2i(2, 2)
	return def


static func warren() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.WARREN
	def.display_name = "Warren"
	def.build_time = 0.0
	def.footprint = Vector2i(2, 2)
	return def


static func storage_hut() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.STOREHOUSE
	def.display_name = "Storage Hut"
	def.build_time = 8.0
	def.wood_cost = 40
	def.stone_cost = 15
	def.footprint = Vector2i(2, 2)
	return def


static func sleeping_pit() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.SLEEPING_PIT
	def.display_name = "Sleeping Pit"
	def.build_time = 8.0
	def.wood_cost = 20
	def.stone_cost = 5
	def.footprint = Vector2i(2, 2)
	return def


static func forager_post() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.FORAGER_POST
	def.display_name = "Forager Post"
	def.build_time = 8.0
	def.wood_cost = 25
	def.stone_cost = 5
	def.footprint = Vector2i(2, 2)
	return def


static func mushroom_farm() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.MUSHROOM_FARM
	def.display_name = "Mushroom Farm"
	def.build_time = 10.0
	def.wood_cost = 30
	def.stone_cost = 10
	def.footprint = Vector2i(2, 2)
	return def


static func breeder_hut() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.BREEDER_HUT
	def.display_name = "Breeder Hut"
	def.build_time = 12.0
	def.wood_cost = 35
	def.stone_cost = 15
	def.footprint = Vector2i(2, 2)
	return def


static func shrine() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.SHRINE
	def.display_name = "Shrine"
	def.build_time = 14.0
	def.wood_cost = 40
	def.stone_cost = 25
	def.footprint = Vector2i(2, 2)
	return def


static func guard_post() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.GUARD_POST
	def.display_name = "Guard Post"
	def.build_time = 10.0
	def.wood_cost = 30
	def.stone_cost = 20
	def.footprint = Vector2i(2, 2)
	return def


static func watchtower() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.WATCHTOWER
	def.display_name = "Watchtower"
	def.build_time = 12.0
	def.wood_cost = 35
	def.stone_cost = 30
	def.footprint = Vector2i(1, 1)
	return def


static func burial_grounds() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.BURIAL_GROUNDS
	def.display_name = "Burial Grounds"
	def.build_time = 10.0
	def.wood_cost = 20
	def.stone_cost = 15
	def.footprint = Vector2i(2, 2)
	return def


static func lumber_hut() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.LUMBER_HUT
	def.display_name = "Lumber Hut"
	def.build_time = 10.0
	def.wood_cost = 30
	def.footprint = Vector2i(2, 2)
	return def


static func quarry() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.QUARRY
	def.display_name = "Quarry"
	def.build_time = 10.0
	def.wood_cost = 25
	def.stone_cost = 10
	def.footprint = Vector2i(2, 2)
	return def


static func barracks() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.BARRACKS
	def.display_name = "Barracks"
	def.build_time = 15.0
	def.wood_cost = 40
	def.stone_cost = 20
	def.footprint = Vector2i(2, 2)
	return def


static func blacksmith() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.BLACKSMITH
	def.display_name = "Blacksmith"
	def.build_time = 15.0
	def.wood_cost = 30
	def.stone_cost = 30
	def.footprint = Vector2i(2, 2)
	return def


static func cook_hut() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.COOK_HUT
	def.display_name = "Cook Hut"
	def.build_time = 10.0
	def.wood_cost = 25
	def.stone_cost = 10
	def.footprint = Vector2i(2, 2)
	return def


static func shaman_hut() -> BuildingDef:
	var def := BuildingDef.new()
	def.kind = Defs.BuildingKind.SHAMAN_HUT
	def.display_name = "Shaman Hut"
	def.build_time = 15.0
	def.wood_cost = 30
	def.stone_cost = 20
	def.footprint = Vector2i(2, 2)
	return def


static func player_placeable() -> Array[BuildingDef]:
	return [
		storage_hut(),
		sleeping_pit(),
		forager_post(),
		mushroom_farm(),
		breeder_hut(),
		shrine(),
		guard_post(),
		watchtower(),
		burial_grounds(),
		barracks(),
		blacksmith(),
		cook_hut(),
		shaman_hut(),
	]
