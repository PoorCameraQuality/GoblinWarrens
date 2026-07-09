class_name PopulationBrackets
extends RefCounted

## Soft anti-snowball work-efficiency penalties by colony population (WC3 upkeep shape).

enum Bracket {
	COMFORTABLE,
	CROWDED,
	OVERSTRETCHED,
	CHAOTIC,
}


static func bracket_for(population: int) -> Bracket:
	if population <= Constants.POP_BRACKET_COMFORTABLE_MAX:
		return Bracket.COMFORTABLE
	if population <= Constants.POP_BRACKET_CROWDED_MAX:
		return Bracket.CROWDED
	if population <= Constants.POP_BRACKET_OVERSTRETCHED_MAX:
		return Bracket.OVERSTRETCHED
	return Bracket.CHAOTIC


static func work_efficiency_multiplier(population: int, warren_level: int = 1) -> float:
	match bracket_for(population):
		Bracket.COMFORTABLE:
			return 1.0
		Bracket.CROWDED:
			return Constants.POP_EFFICIENCY_CROWDED
		Bracket.OVERSTRETCHED:
			return Constants.POP_EFFICIENCY_OVERSTRETCHED
		Bracket.CHAOTIC:
			if warren_level >= Constants.WARREN_LEVEL_CROWDING_MITIGATION:
				return 1.0
			return Constants.POP_EFFICIENCY_CHAOTIC
	return 1.0


static func bracket_label(population: int, warren_level: int = 1) -> String:
	match bracket_for(population):
		Bracket.COMFORTABLE:
			return "Comfortable"
		Bracket.CROWDED:
			return "Crowded"
		Bracket.OVERSTRETCHED:
			return "Overstretched"
		Bracket.CHAOTIC:
			if warren_level >= Constants.WARREN_LEVEL_CROWDING_MITIGATION:
				return "Sprawl (Warren calm)"
			return "Chaotic sprawl"
	return "Comfortable"


static func penalty_percent(population: int, warren_level: int = 1) -> int:
	var mult: float = work_efficiency_multiplier(population, warren_level)
	return int(round((1.0 - mult) * 100.0))
