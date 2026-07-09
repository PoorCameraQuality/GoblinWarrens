extends GutTest

## M4 food upkeep: fed goblins stay healthy; shortage applies starvation.


func test_food_upkeep_consumes_stockpile() -> void:
	var stock := Stockpile.new()
	stock.amounts[Defs.ResourceKind.FOOD] = 20
	var goblins: Array[Goblin] = []
	var upkeep := FoodUpkeep.new()
	var collapsed := upkeep.tick(Constants.FOOD_UPKEEP_INTERVAL, stock, goblins)
	assert_false(collapsed)


func test_foblins_do_not_consume_food() -> void:
	var stock := Stockpile.new()
	stock.amounts[Defs.ResourceKind.FOOD] = 10
	var worker := Goblin.new()
	var foblin := Goblin.new()
	foblin.is_foblin_unit = true
	var goblins: Array[Goblin] = [worker, foblin]
	var upkeep := FoodUpkeep.new()
	assert_eq(FoodUpkeep.count_food_consumers(goblins), 1)
	upkeep.tick(Constants.FOOD_UPKEEP_INTERVAL, stock, goblins)
	assert_eq(stock.get_amount(Defs.ResourceKind.FOOD), 10 - Constants.FOOD_PER_GOBLIN_PER_TICK)


func test_only_foblins_skip_upkeep_entirely() -> void:
	var stock := Stockpile.new()
	stock.amounts[Defs.ResourceKind.FOOD] = 100
	var foblin := Goblin.new()
	foblin.is_foblin_unit = true
	var goblins: Array[Goblin] = [foblin]
	var upkeep := FoodUpkeep.new()
	upkeep.tick(Constants.FOOD_UPKEEP_INTERVAL, stock, goblins)
	assert_eq(stock.get_amount(Defs.ResourceKind.FOOD), 100)


func test_food_shortage_after_depletion() -> void:
	var stock := Stockpile.new()
	stock.amounts[Defs.ResourceKind.FOOD] = 0
	var goblin := Goblin.new()
	var goblins: Array[Goblin] = [goblin]
	var upkeep := FoodUpkeep.new()
	var collapsed := false
	for i in range(Constants.FOOD_COLLAPSE_TICKS):
		collapsed = upkeep.tick(Constants.FOOD_UPKEEP_INTERVAL, stock, goblins)
	assert_true(collapsed)
