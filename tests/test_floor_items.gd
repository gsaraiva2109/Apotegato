extends GutTest
## Confere os ingredientes do andar: só os da região e da paridade certas, em
## células alcançáveis, e a coleta para a mochila com o contador na tela.

const FloorScene := preload("res://scenes/region/floor.tscn")

var _floor: RegionFloor


func before_each() -> void:
	GameState.new_game()
	GameState.start_region(Regions.CAATINGA)
	_floor = autofree(FloorScene.instantiate())
	add_child(_floor)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	GameState.new_game()


func _room() -> Room:
	return _floor.get_node("Room")


func _player() -> Player:
	return _floor.get_node("World/Player")


func _ids(pickups: Array[IngredientPickup]) -> Array:
	var ids := []
	for pickup in pickups:
		ids.append(pickup.ingredient_id)
	ids.sort()
	return ids


func test_floor_one_has_the_odd_ingredients_of_the_region() -> void:
	assert_eq(_ids(_floor.get_pickups()), ["alecrim_pimenta", "castanha_caju"])


func test_only_ingredients_of_the_right_region_and_parity_appear() -> void:
	# todas as regiões, nos seis primeiros andares, contra a Tabela 2 do CSV
	for region in Regions.IDS:
		GameState.start_region(region)
		for floor_number in 6:
			var parity := GameState.floor_parity()
			_floor.generate_floor()
			var expected := []
			for ingredient in IngredientData.get_ingredients_in(region, parity):
				expected.append(ingredient.id)
			expected.sort()
			assert_eq(
				_ids(_floor.get_pickups()), expected, "%s, andar %d" % [region, floor_number + 1]
			)
			for pickup in _floor.get_pickups():
				var ingredient := IngredientData.get_ingredient(pickup.ingredient_id)
				assert_eq(ingredient.region, region)
				assert_eq(ingredient.parity, parity)
			GameState.climb_floor()


func test_pickups_sit_on_free_cells_reachable_from_the_entry() -> void:
	for i in 40:
		_floor.generate_floor()
		var layout := _room().layout
		var reachable := GridBfs.distances(layout.grid, layout.entry_cell)
		var cells := {}
		for pickup in _floor.get_pickups():
			var cell := MazeGrid.position_to_cell(pickup.position)
			assert_true(reachable.has(cell), "Ingrediente inalcançável")
			assert_ne(cell, layout.exit_cell)
			assert_ne(cell, layout.entry_cell)
			cells[cell] = true
		assert_eq(cells.size(), _floor.get_pickups().size(), "Dois ingredientes na mesma célula")


func test_new_floor_replaces_the_pickups() -> void:
	var before := _floor.get_pickups()
	_floor._on_door_choice_made(DoorMenu.UP)
	var after := _floor.get_pickups()
	assert_eq(_ids(after), ["acerola", "licuri"], "Andar 2 da Caatinga é par")
	for pickup in before:
		assert_false(pickup in after)


func test_touching_a_pickup_moves_it_to_the_backpack() -> void:
	var pickup := _floor.get_pickups()[0]
	var id := pickup.ingredient_id
	pickup.touched.emit(pickup)
	assert_eq(GameState.backpack.count(id), 1)
	assert_eq(_floor.get_pickups().size(), 1, "Sumiu do chão")
	assert_true(pickup.is_queued_for_deletion())


func test_walking_over_a_pickup_collects_it() -> void:
	var pickup := _floor.get_pickups()[0]
	var id := pickup.ingredient_id
	_player().position = pickup.position
	await wait_physics_frames(3)
	assert_eq(GameState.backpack.count(id), 1)


func test_counter_shows_what_was_collected() -> void:
	var pickup := _floor.get_pickups()[0]
	pickup.touched.emit(pickup)
	var label: Label = _floor.get_node("Hud/Root/BackpackPanel/BackpackLabel")
	assert_eq(label.text, Hud.backpack_text(GameState.backpack))
	assert_string_contains(label.text, "Mochila 1/6")
	var message: Label = _floor.get_node("Hud/Root/MessageLabel")
	assert_true(message.visible)
	assert_string_contains(message.text, "Pegou")


func test_full_backpack_warns_and_leaves_the_item_on_the_floor() -> void:
	for id in ["buriti", "camu_camu", "mel", "sardinha", "pequi", "mulungu"]:
		GameState.backpack.add(id)
	var pickup := _floor.get_pickups()[0]
	pickup.touched.emit(pickup)
	assert_eq(GameState.backpack.count(pickup.ingredient_id), 0)
	assert_eq(_floor.get_pickups().size(), 2, "Continua no chão")
	var message: Label = _floor.get_node("Hud/Root/MessageLabel")
	assert_true(message.visible)
	assert_string_contains(message.text, "Mochila cheia")


func test_collected_items_stay_in_the_backpack_across_floors() -> void:
	var pickup := _floor.get_pickups()[0]
	var id := pickup.ingredient_id
	pickup.touched.emit(pickup)
	_floor._on_door_choice_made(DoorMenu.UP)
	assert_eq(GameState.backpack.count(id), 1)
	var label: Label = _floor.get_node("Hud/Root/BackpackPanel/BackpackLabel")
	assert_string_contains(label.text, "x1")
