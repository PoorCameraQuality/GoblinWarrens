class_name MvpEvaluator
extends RefCounted

## Win/loss checks for the internal MVP demo.


static func check_loss(colony: GoblinWarrenColony) -> Defs.DemoOutcome:
	var warren := colony.get_warren()
	if warren == null or not is_instance_valid(warren) or warren.is_destroyed():
		return Defs.DemoOutcome.LOSS
	if colony.count_living_goblins() <= 0:
		return Defs.DemoOutcome.LOSS
	if colony.is_food_collapsed():
		return Defs.DemoOutcome.LOSS
	return Defs.DemoOutcome.NONE


static func check_win(colony: GoblinWarrenColony, day: int, raid_cleared: bool) -> Defs.DemoOutcome:
	if day < 7:
		return Defs.DemoOutcome.NONE
	if not raid_cleared:
		return Defs.DemoOutcome.NONE
	if not colony.has_building_kind(Defs.BuildingKind.SHRINE):
		return Defs.DemoOutcome.NONE
	if not colony.has_basic_defense():
		return Defs.DemoOutcome.NONE
	if colony.get_warren() == null or not is_instance_valid(colony.get_warren()):
		return Defs.DemoOutcome.LOSS
	if colony.get_warren().is_destroyed():
		return Defs.DemoOutcome.LOSS
	return Defs.DemoOutcome.WIN
