extends GutTest
## Confere o estado da campanha: região, andar, paridade e que mochila e estoque
## sobrevivem a trocas de região e à ida à cabana.


func before_each() -> void:
	GameState.new_game()


func after_all() -> void:
	GameState.new_game()


func test_starting_a_region_goes_to_floor_one() -> void:
	GameState.start_region(Regions.CERRADO)
	assert_eq(GameState.current_region, "cerrado")
	assert_eq(GameState.current_floor, 1)


func test_climbing_adds_one_floor() -> void:
	GameState.start_region(Regions.CERRADO)
	GameState.climb_floor()
	GameState.climb_floor()
	assert_eq(GameState.current_floor, 3)


func test_parity_flips_on_every_floor() -> void:
	GameState.start_region(Regions.LITORAL)
	assert_eq(GameState.floor_parity(), "impar", "O andar 1 é ímpar")
	GameState.climb_floor()
	assert_eq(GameState.floor_parity(), "par")
	GameState.climb_floor()
	assert_eq(GameState.floor_parity(), "impar")


func test_parity_values_match_the_csv() -> void:
	var parities := {}
	for ingredient in IngredientData.get_all_ingredients():
		parities[ingredient.parity] = true
	assert_true(parities.has(GameState.PARITY_ODD))
	assert_true(parities.has(GameState.PARITY_EVEN))
	assert_eq(parities.size(), 2)


func test_changing_region_goes_back_to_floor_one() -> void:
	GameState.start_region(Regions.CAATINGA)
	GameState.climb_floor()
	GameState.climb_floor()
	GameState.start_region(Regions.AMAZONIA)
	assert_eq(GameState.current_region, "amazonia")
	assert_eq(GameState.current_floor, 1)


func test_backpack_and_stock_survive_region_changes_and_the_cabin() -> void:
	GameState.start_region(Regions.CAATINGA)
	GameState.backpack.add("acerola", 2)
	GameState.stock.store("mel")
	GameState.climb_floor()
	GameState.start_region(Regions.LITORAL)
	GameState.leave_region()
	GameState.start_region(Regions.CERRADO)
	assert_eq(GameState.backpack.count("acerola"), 2)
	assert_eq(GameState.stock.count("mel"), 1)


func test_leaving_the_region_clears_only_the_place() -> void:
	GameState.start_region(Regions.CAATINGA)
	GameState.climb_floor()
	GameState.backpack.add("licuri")
	GameState.leave_region()
	assert_eq(GameState.current_region, "")
	assert_eq(GameState.current_floor, 1)
	assert_eq(GameState.backpack.count("licuri"), 1)


func test_new_game_clears_everything() -> void:
	GameState.start_region(Regions.CAATINGA)
	GameState.backpack.add("licuri")
	GameState.stock.store("mel")
	GameState.new_game()
	assert_eq(GameState.current_region, "")
	assert_true(GameState.backpack.is_empty())
	assert_true(GameState.stock.is_empty())


func test_signals_are_emitted() -> void:
	watch_signals(GameState)
	GameState.start_region(Regions.CERRADO)
	GameState.climb_floor()
	assert_signal_emitted_with_parameters(GameState, "region_started", ["cerrado"])
	assert_signal_emitted_with_parameters(GameState, "floor_climbed", [2])


func test_scene_paths_exist() -> void:
	for path in [ScenePaths.CABIN, ScenePaths.FLOOR]:
		assert_true(ResourceLoader.exists(path), "Falta a cena %s" % path)
