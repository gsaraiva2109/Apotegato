extends GutTest
## Confere as criaturas do andar: quantidade pelo parâmetro, longe da entrada,
## sem fechar o caminho, e cada uma derrotada aumenta a luz do andar.

const FloorScene := preload("res://scenes/region/floor.tscn")

var _floor: RegionFloor


func before_each() -> void:
	GameState.new_game()
	GameState.start_region(Regions.MATA_ATLANTICA)
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


func _light() -> PlayerLight:
	return _floor.get_node("World/Player/Light")


## Quantas criaturas o gerador reservou no andar atual. Em raros mapas ele
## entrega menos que o parâmetro (ver `MazeParams.entities`), então os testes
## comparam com o que foi reservado e confirmam o teto pelo parâmetro.
func _reserved() -> int:
	return _room().layout.creature_cells.size()


func test_amount_follows_the_entities_param() -> void:
	assert_eq(_floor.get_creatures().size(), _reserved())
	assert_lte(_floor.get_creatures().size(), _room().params.entities)
	_room().params.entities = 2
	_floor.generate_floor()
	assert_eq(_floor.get_creatures().size(), _reserved())
	assert_lte(_floor.get_creatures().size(), 2)
	_room().params.entities = 0
	_floor.generate_floor()
	assert_eq(_floor.get_creatures().size(), 0)


func test_creatures_sit_on_the_reserved_cells_far_from_the_entry() -> void:
	for i in 30:
		_floor.generate_floor()
		var layout := _room().layout
		var from_entry := GridBfs.distances(layout.grid, layout.entry_cell)
		for creature in _floor.get_creatures():
			var cell := MazeGrid.position_to_cell(creature.position)
			assert_true(cell in layout.creature_cells)
			assert_gte(from_entry[cell], MazeGenerator.MIN_CREATURE_ENTRY_STEPS)


func test_new_floor_replaces_the_creatures() -> void:
	var before := _floor.get_creatures()
	_floor._on_door_choice_made(DoorMenu.UP)
	var after := _floor.get_creatures()
	for creature in before:
		assert_false(creature in after)
	assert_eq(after.size(), _reserved())


func test_defeating_creatures_is_optional_to_collect_and_climb() -> void:
	# Com todas vivas, os ingredientes e a porta seguem alcançáveis pela grade
	# (criaturas fechadas como parede) e a subida de andar não depende delas.
	for i in 20:
		_floor.generate_floor()
		var layout := _room().layout
		var grid := layout.grid
		for cell in layout.creature_cells:
			grid.set_blocked(cell)
		var reachable := GridBfs.distances(grid, layout.entry_cell)
		assert_true(reachable.has(layout.exit_cell))
		for pickup in _floor.get_pickups():
			assert_true(reachable.has(MazeGrid.position_to_cell(pickup.position)))
	_floor._on_door_choice_made(DoorMenu.UP)
	assert_eq(GameState.current_floor, 2)
	assert_gt(_floor.get_creatures().size(), 0)


func test_each_defeated_creature_grows_the_light() -> void:
	assert_almost_eq(_light().texture_scale, 0.6, 0.0001)
	var creatures := _floor.get_creatures()
	for i in 2:
		for hit in 3:
			creatures[i].take_scratch()
	assert_eq(_light().defeated, 2)
	assert_almost_eq(_light().texture_scale, 0.84, 0.0001)


func test_scratching_a_creature_through_the_player_raises_the_light() -> void:
	var creature := _floor.get_creatures()[0]
	_player().facing = Vector2.RIGHT
	_player().attack_cooldown = 0.0
	for i in 3:
		creature.global_position = _player().global_position + Vector2(28, 0)
		await wait_physics_frames(2)
		_player().try_attack()
	assert_true(creature.is_defeated())
	assert_eq(_light().defeated, 1)
	assert_almost_eq(_light().texture_scale, 0.72, 0.0001)
	assert_eq(_floor.get_creatures().size(), _reserved() - 1)


func test_light_resets_on_the_next_floor_after_defeats() -> void:
	var creature := _floor.get_creatures()[0]
	for hit in 3:
		creature.take_scratch()
	assert_gt(_light().texture_scale, 0.6)
	_floor._on_door_choice_made(DoorMenu.UP)
	assert_almost_eq(_light().texture_scale, 0.6, 0.0001)
