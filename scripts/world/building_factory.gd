class_name BuildingFactory
extends RefCounted

const _VisualCatalog := preload("res://scripts/art/visual_catalog.gd")
const _VisualAttacher := preload("res://scripts/core/visual_attacher.gd")

## Spawns completed buildings and activates their gameplay behavior.


static func create_building_node(kind: Defs.BuildingKind) -> Building:
	match kind:
		Defs.BuildingKind.WARREN:
			return Warren.new()
		Defs.BuildingKind.MUSHROOM_FARM:
			return MushroomFarm.new()
		Defs.BuildingKind.FORAGER_POST:
			return ForagerPost.new()
		Defs.BuildingKind.BREEDER_HUT:
			return BreederHut.new()
		Defs.BuildingKind.SHRINE:
			return ShrineBuilding.new()
		Defs.BuildingKind.BURIAL_GROUNDS:
			return BurialGrounds.new()
		Defs.BuildingKind.GUARD_POST:
			return GuardPost.new()
		Defs.BuildingKind.WATCHTOWER:
			return Watchtower.new()
		Defs.BuildingKind.BARRACKS:
			return Barracks.new()
		Defs.BuildingKind.BLACKSMITH:
			return BlacksmithBuilding.new()
		Defs.BuildingKind.COOK_HUT:
			return CookHut.new()
		Defs.BuildingKind.SHAMAN_HUT:
			return ShamanHut.new()
		_:
			return Building.new()


static func attach_mesh(building: Building) -> void:
	if building.get_node_or_null("Mesh") != null:
		return
	var mesh := CSGBox3D.new()
	mesh.name = "Mesh"
	mesh.position = Vector3(0.0, 0.5, 0.0)
	building.add_child(mesh)


static func attach_visual(building: Building, kind: Defs.BuildingKind) -> void:
	attach_mesh(building)
	var path: String = _VisualCatalog.building_wrapper(kind)
	var scale := _VisualCatalog.building_visual_scale(kind, path)
	_VisualAttacher.try_attach(building, path, ["Mesh"], scale)


static func finish_construction(
	colony: GoblinWarrenColony,
	cell: Vector2i,
	def: BuildingDef,
	placement_yaw: float = 0.0,
) -> void:
	match def.kind:
		Defs.BuildingKind.STOREHOUSE:
			colony.spawn_completed_storehouse(cell, def, placement_yaw)
		Defs.BuildingKind.LUMBER_HUT:
			colony.spawn_completed_building(cell, def, placement_yaw)
			colony.spawn_building_gather_node(cell, def.footprint, Defs.ResourceKind.WOOD)
		Defs.BuildingKind.QUARRY:
			colony.spawn_completed_building(cell, def, placement_yaw)
			colony.spawn_building_gather_node(cell, def.footprint, Defs.ResourceKind.STONE)
		Defs.BuildingKind.GOLD_MINE:
			colony.spawn_completed_building(cell, def, placement_yaw)
			colony.spawn_building_gather_node(cell, def.footprint, Defs.ResourceKind.GOLD)
		Defs.BuildingKind.SLEEPING_PIT:
			colony.spawn_completed_building(cell, def, placement_yaw)
			colony.add_housing_bonus(Constants.HOUSING_PER_SLEEPING_PIT)
		Defs.BuildingKind.MUSHROOM_FARM:
			colony.spawn_mushroom_farm(cell, def, placement_yaw)
		Defs.BuildingKind.FORAGER_POST:
			colony.spawn_forager_post(cell, def, placement_yaw)
		Defs.BuildingKind.BREEDER_HUT:
			colony.spawn_breeder_hut(cell, def, placement_yaw)
		Defs.BuildingKind.SHRINE:
			colony.spawn_shrine(cell, def, placement_yaw)
		Defs.BuildingKind.BURIAL_GROUNDS:
			colony.spawn_burial_grounds(cell, def, placement_yaw)
		Defs.BuildingKind.GUARD_POST:
			colony.spawn_guard_post(cell, def, placement_yaw)
		Defs.BuildingKind.WATCHTOWER:
			colony.spawn_watchtower(cell, def, placement_yaw)
		Defs.BuildingKind.BARRACKS:
			colony.spawn_barracks(cell, def, placement_yaw)
		Defs.BuildingKind.BLACKSMITH:
			colony.spawn_blacksmith(cell, def, placement_yaw)
		Defs.BuildingKind.COOK_HUT:
			colony.spawn_cook_hut(cell, def, placement_yaw)
		Defs.BuildingKind.SHAMAN_HUT:
			colony.spawn_shaman_hut(cell, def, placement_yaw)
		_:
			colony.spawn_completed_building(cell, def, placement_yaw)
	colony.on_building_finished(def.kind)
