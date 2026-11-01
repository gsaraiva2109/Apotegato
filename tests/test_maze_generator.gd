extends GutTest
## Confere o gerador de andares: parâmetros com limite, entrada e saída em
## células livres, semente, e que nenhum andar sorteado tem ingrediente,
## criatura ou porta inalcançável.

## Quantos andares sortear nos testes "em massa".
const MANY_FLOORS := 200


func _params(width := 30, height := 17, obstacles := 16, entities := 4, items := 3) -> MazeParams:
	var params := MazeParams.new()
	params.width = width
	params.height = height
	params.obstacles = obstacles
	params.entities = entities
	params.items = items
	return params


func _signature(layout: MazeLayout) -> String:
	return str(
		[
			layout.grid.free_cells(),
			layout.entry_cell,
			layout.exit_cell,
			layout.item_cells,
			layout.creature_cells
		]
	)


func test_params_are_limited() -> void:
	var params := _params(1000, 1000, 1000, 1000, 1000)
	assert_eq(params.width, MazeParams.MAX_WIDTH)
	assert_eq(params.height, MazeParams.MAX_HEIGHT)
	assert_eq(params.obstacles, MazeParams.MAX_OBSTACLES)
	assert_eq(params.entities, MazeParams.MAX_ENTITIES)
	assert_eq(params.items, MazeParams.MAX_ITEMS)
	params = _params(-5, -5, -5, -5, -5)
	assert_eq(params.width, MazeParams.MIN_WIDTH)
	assert_eq(params.height, MazeParams.MIN_HEIGHT)
	assert_eq(params.obstacles, 0)
	assert_eq(params.entities, 0)
	assert_eq(params.items, 0)


func test_grid_has_the_requested_size_and_a_wall_border() -> void:
	var layout := MazeGenerator.generate(_params(24, 12), 1)
	assert_eq(layout.grid.width, 24)
	assert_eq(layout.grid.height, 12)
	for x in 24:
		assert_true(layout.grid.is_blocked(Vector2i(x, 0)))
		assert_true(layout.grid.is_blocked(Vector2i(x, 11)))
	for y in 12:
		assert_true(layout.grid.is_blocked(Vector2i(0, y)))
		assert_true(layout.grid.is_blocked(Vector2i(23, y)))


func test_entry_and_exit_are_free_and_different() -> void:
	for i in 50:
		var layout := MazeGenerator.generate(_params(), i)
		assert_true(layout.grid.is_free(layout.entry_cell))
		assert_true(layout.grid.is_free(layout.exit_cell))
		assert_ne(layout.entry_cell, layout.exit_cell)


func test_same_seed_gives_the_same_floor() -> void:
	var first := MazeGenerator.generate(_params(), 12345)
	var second := MazeGenerator.generate(_params(), 12345)
	assert_eq(_signature(first), _signature(second))
	assert_eq(first.random_seed, 12345)


func test_different_seeds_give_different_floors() -> void:
	var signatures := {}
	for i in 10:
		signatures[_signature(MazeGenerator.generate(_params(), i))] = true
	assert_gt(signatures.size(), 1)


func test_each_call_without_seed_gives_a_new_floor() -> void:
	var signatures := {}
	var seeds := {}
	for i in 10:
		var layout := MazeGenerator.generate(_params())
		signatures[_signature(layout)] = true
		seeds[layout.random_seed] = true
	assert_gt(signatures.size(), 1, "Mesmo andar, mapas diferentes")
	assert_gt(seeds.size(), 1)


func test_the_reported_seed_reproduces_the_floor() -> void:
	var original := MazeGenerator.generate(_params())
	var again := MazeGenerator.generate(_params(), original.random_seed)
	assert_eq(_signature(again), _signature(original))


func test_item_and_creature_counts_follow_the_params() -> void:
	var layout := MazeGenerator.generate(_params(30, 17, 16, 5, 4), 7)
	assert_eq(layout.item_cells.size(), 4)
	assert_eq(layout.creature_cells.size(), 5)
	layout = MazeGenerator.generate(_params(30, 17, 16, 0, 0), 7)
	assert_true(layout.item_cells.is_empty())
	assert_true(layout.creature_cells.is_empty())


func test_obstacles_param_changes_the_amount_of_walls() -> void:
	var open := MazeGenerator.generate(_params(30, 17, 0), 3)
	var busy := MazeGenerator.generate(_params(30, 17, 40), 3)
	assert_eq(open.grid.free_cells().size(), 28 * 15)
	assert_lt(busy.grid.free_cells().size(), open.grid.free_cells().size())


func test_many_random_floors_have_nothing_unreachable() -> void:
	for i in MANY_FLOORS:
		var layout := MazeGenerator.generate(_params())
		var reachable := GridBfs.distances(layout.grid, layout.entry_cell)
		var label := "semente %d" % layout.random_seed
		assert_true(reachable.has(layout.exit_cell), "Porta inalcançável, %s" % label)
		assert_eq(layout.item_cells.size(), 3, "Faltou ingrediente, %s" % label)
		for cell in layout.item_cells:
			assert_true(reachable.has(cell), "Ingrediente inalcançável, %s" % label)
		for cell in layout.creature_cells:
			assert_true(reachable.has(cell), "Criatura inalcançável, %s" % label)


func test_creatures_keep_away_from_the_entry_and_the_exit() -> void:
	for i in 50:
		var layout := MazeGenerator.generate(_params(), i)
		var from_entry := GridBfs.distances(layout.grid, layout.entry_cell)
		var from_exit := GridBfs.distances(layout.grid, layout.exit_cell)
		for cell in layout.creature_cells:
			assert_gte(from_entry[cell], MazeGenerator.MIN_CREATURE_ENTRY_STEPS)
			assert_gte(from_exit[cell], MazeGenerator.MIN_CREATURE_EXIT_STEPS)
			assert_false(cell in layout.item_cells)


func test_creatures_never_block_the_only_path() -> void:
	# Com todas as criaturas como parede, saída e ingredientes seguem alcançáveis.
	for i in 100:
		var layout := MazeGenerator.generate(_params(30, 17, 30, 6, 4), i)
		var grid := layout.grid
		for cell in layout.creature_cells:
			grid.set_blocked(cell)
		var reachable := GridBfs.distances(grid, layout.entry_cell)
		assert_true(reachable.has(layout.exit_cell), "Saída fechada, semente %d" % i)
		for cell in layout.item_cells:
			assert_true(reachable.has(cell), "Ingrediente fechado, semente %d" % i)


func test_extreme_params_still_give_a_valid_floor() -> void:
	var sizes := [
		Vector2i(MazeParams.MIN_WIDTH, MazeParams.MIN_HEIGHT),
		Vector2i(MazeParams.MAX_WIDTH, MazeParams.MAX_HEIGHT),
	]
	for size: Vector2i in sizes:
		for i in 20:
			var params := _params(
				size.x,
				size.y,
				MazeParams.MAX_OBSTACLES,
				MazeParams.MAX_ENTITIES,
				MazeParams.MAX_ITEMS
			)
			var layout := MazeGenerator.generate(params, i)
			var reachable := GridBfs.distances(layout.grid, layout.entry_cell)
			assert_true(reachable.has(layout.exit_cell), "%s, semente %d" % [size, i])
			assert_eq(layout.item_cells.size(), MazeParams.MAX_ITEMS)
			for cell in layout.item_cells:
				assert_true(reachable.has(cell))
