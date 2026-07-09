class_name DemoDayCatalog
extends RefCounted

## Day-by-day briefing copy aligned with docs/goblin-warrens-design.md §35.


static func day_title(day: int) -> String:
	match day:
		1: return "Day 1 — Filthy Beginnings"
		2: return "Day 2 — The Camp Breathes"
		3: return "Day 3 — More Goblins"
		4: return "Day 4 — Faith in the Mud"
		5: return "Day 5 — Bones Remember"
		6: return "Day 6 — They Found Us"
		7: return "Day 7 — First Raid"
		_: return "Day %d" % day


static func briefing(day: int) -> String:
	match day:
		1:
			return (
				"Six Foblins start the camp — gather wood and stone, haul to the Storehouse.\n"
				+ "Build: Storage Hut (1), Sleeping Pit (2), then Forager Post (3) or Mushroom Farm (4).\n"
				+ "Foblins need no food; build food production before Breeder Hut workers arrive."
			)
		2:
			return (
				"Expand food production before rations run dry.\n"
				+ "A surface beast may prowl today — select goblins and fight near the Warren.\n"
				+ "Build key: Mushroom Farm (4) for passive food."
			)
		3:
			return (
				"Breeder Hut (5) spawns proper Goblin workers over time.\n"
				+ "Your starting Foblins are expendable — workers do the real building.\n"
				+ "Build Sleeping Pits (2) before the warren overflows.\n"
				+ "Threat: food demand rises once workers arrive."
			)
		4:
			return (
				"Build Shrine (6). Workers will pray and generate Magic.\n"
				+ "Save magic for Day 7 — Bless Defenders (top-right) before the raid.\n"
				+ "Threat: minor sickness from hunger if you neglect farms."
			)
		5:
			return (
				"If a named goblin dies, build Burial Grounds (9) to bury them.\n"
				+ "Revive costs 30 magic — only works after burial.\n"
				+ "Threat: beasts or starvation."
			)
		6:
			return (
				"Human scout today — raid hits tomorrow!\n"
				+ "Build Guard Post (7) or Watchtower (8) NOW.\n"
				+ "Rally goblins near the Warren. Stock magic for Bless."
			)
		7:
			return (
				"RAID DAY — human militia attack the Warren!\n"
				+ "Cast Bless Defenders, select goblins, right-click enemies.\n"
				+ "Win: repel raid + Shrine + defense built + Warren alive."
			)
		_:
			return "Survive and grow the warren."


static func build_hint(day: int) -> String:
	match day:
		1: return "Priority: Forager Post (3) or Mushroom Farm (4)"
		2: return "Priority: Mushroom Farm (4) + watch for beast"
		3: return "Priority: Breeder Hut (5) for workers, then Sleeping Pit (2)"
		4: return "Priority: Shrine (6)"
		5: return "Priority: Burial Grounds (9) if anyone dies"
		6: return "Priority: Guard Post (7) or Watchtower (8)"
		7: return "Priority: Bless Defenders + defend Warren"
		_: return ""
