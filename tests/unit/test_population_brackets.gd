extends GutTest

## Population bracket work-efficiency penalties (WC3-inspired soft upkeep).


func test_comfortable_no_penalty() -> void:
	assert_eq(PopulationBrackets.work_efficiency_multiplier(0), 1.0)
	assert_eq(PopulationBrackets.work_efficiency_multiplier(30), 1.0)
	assert_eq(PopulationBrackets.penalty_percent(20), 0)


func test_crowded_soft_penalty() -> void:
	assert_eq(PopulationBrackets.work_efficiency_multiplier(31), Constants.POP_EFFICIENCY_CROWDED)
	assert_eq(PopulationBrackets.work_efficiency_multiplier(50), Constants.POP_EFFICIENCY_CROWDED)
	assert_eq(PopulationBrackets.penalty_percent(40), 10)


func test_overstretched_penalty() -> void:
	assert_eq(
		PopulationBrackets.work_efficiency_multiplier(51),
		Constants.POP_EFFICIENCY_OVERSTRETCHED,
	)
	assert_eq(
		PopulationBrackets.work_efficiency_multiplier(75),
		Constants.POP_EFFICIENCY_OVERSTRETCHED,
	)
	assert_eq(PopulationBrackets.penalty_percent(60), 15)


func test_chaotic_highest_penalty() -> void:
	assert_eq(
		PopulationBrackets.work_efficiency_multiplier(76, 1),
		Constants.POP_EFFICIENCY_CHAOTIC,
	)
	assert_eq(PopulationBrackets.penalty_percent(100, 1), 25)


func test_warren_upgrade_mitigates_chaotic_bracket() -> void:
	assert_eq(PopulationBrackets.work_efficiency_multiplier(80, 2), Constants.POP_EFFICIENCY_CHAOTIC)
	assert_eq(PopulationBrackets.work_efficiency_multiplier(80, 3), 1.0)
	assert_eq(PopulationBrackets.penalty_percent(80, 3), 0)


func test_bracket_boundaries() -> void:
	assert_eq(PopulationBrackets.bracket_for(30), PopulationBrackets.Bracket.COMFORTABLE)
	assert_eq(PopulationBrackets.bracket_for(31), PopulationBrackets.Bracket.CROWDED)
	assert_eq(PopulationBrackets.bracket_for(50), PopulationBrackets.Bracket.CROWDED)
	assert_eq(PopulationBrackets.bracket_for(51), PopulationBrackets.Bracket.OVERSTRETCHED)
	assert_eq(PopulationBrackets.bracket_for(76), PopulationBrackets.Bracket.CHAOTIC)
