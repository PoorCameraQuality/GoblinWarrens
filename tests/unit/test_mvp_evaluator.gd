extends GutTest

## MVP win/loss evaluator checks.


func test_loss_when_warren_destroyed() -> void:
	var colony := GoblinWarrenColony.new()
	var warren := Warren.new()
	warren._destroyed = true
	colony._warren = warren
	assert_eq(MvpEvaluator.check_loss(colony), Defs.DemoOutcome.LOSS)


func test_win_requires_shrine_and_defense() -> void:
	var colony := GoblinWarrenColony.new()
	colony._warren = Warren.new()
	assert_eq(
		MvpEvaluator.check_win(colony, 7, true),
		Defs.DemoOutcome.NONE,
	)
