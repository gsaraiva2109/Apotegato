extends GutTest
## Confere a cabana: tamanho do mapa, colisões, Mingau e pontos de interação.

const CabinScene := preload("res://scenes/cabin/cabin.tscn")

var _cabin: Cabin


func before_each() -> void:
	_cabin = autofree(CabinScene.instantiate())
	add_child(_cabin)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false


func test_tilemap_is_30_by_17_tiles() -> void:
	var tiles: TileMapLayer = _cabin.get_node("Tiles")
	assert_eq(tiles.get_used_rect(), Rect2i(0, 0, 30, 17))
	assert_eq(tiles.tile_set.tile_size, Vector2i(32, 32))
	assert_eq(Cabin.ROOM.size, Vector2i(960, 544))


func test_mingau_is_inside_the_cabin() -> void:
	var player: Player = _cabin.get_node("World/Player")
	assert_true(Cabin.ROOM.has_point(Vector2i(player.position)))


func test_walls_stop_the_player() -> void:
	var player: Player = _cabin.get_node("World/Player")
	player.position = Vector2(100, 440)
	await wait_physics_frames(2)
	for i in 120:
		player.velocity = Vector2.LEFT * player.speed
		player.move_and_slide()
	assert_gt(player.position.x, 32.0, "O gato não atravessa a parede")
	assert_lt(player.position.x, 60.0, "O gato chegou perto da parede")


func test_furniture_blocks_the_player() -> void:
	var player: Player = _cabin.get_node("World/Player")
	player.position = Vector2(624, 380)  # abaixo da mesa
	await wait_physics_frames(2)
	for i in 120:
		player.velocity = Vector2.UP * player.speed
		player.move_and_slide()
	assert_gt(player.position.y, 280.0, "O gato não atravessa a mesa")


func test_has_door_journal_and_patient_points() -> void:
	var ids: Array[String] = []
	for area: InteractionArea in _cabin.get_node("Interactions").get_children():
		ids.append(String(area.id))
	ids.sort()
	assert_eq(ids, ["door", "journal", "patient", "stock"])


func test_prompt_shows_only_when_mingau_is_near() -> void:
	var player: Player = _cabin.get_node("World/Player")
	var journal: InteractionArea = _cabin.get_node("Interactions/Journal")
	assert_false(journal.is_prompt_visible(), "Longe: sem aviso")
	player.position = journal.position
	await wait_physics_frames(3)
	assert_true(journal.is_prompt_visible(), "Perto: mostra o E")
	player.position = Vector2(480, 440)
	await wait_physics_frames(3)
	assert_false(journal.is_prompt_visible(), "Saiu: some o aviso")


func test_interact_emits_the_point_id() -> void:
	var player: Player = _cabin.get_node("World/Player")
	var door: InteractionArea = _cabin.get_node("Interactions/Door")
	watch_signals(_cabin)
	assert_false(door.try_interact(), "Longe da porta não interage")
	player.position = door.position
	await wait_physics_frames(3)
	assert_true(door.try_interact())
	assert_signal_emitted_with_parameters(_cabin, "interacted", [&"door"])


func test_areas_use_their_own_size() -> void:
	var journal: InteractionArea = _cabin.get_node("Interactions/Journal")
	var shape: RectangleShape2D = journal.get_node("CollisionShape").shape
	assert_eq(shape.size, journal.size)
	assert_gt(shape.size.x, 64.0)


func test_door_opens_the_region_menu_with_the_six_regions() -> void:
	var menu: RegionMenu = _cabin.get_node("RegionMenu")
	assert_false(menu.is_open())
	var door: InteractionArea = _cabin.get_node("Interactions/Door")
	var player: Player = _cabin.get_node("World/Player")
	player.position = door.position
	await wait_physics_frames(3)
	assert_true(door.try_interact())
	assert_true(menu.is_open())
	assert_true(get_tree().paused, "O jogo pausa enquanto o menu está aberto")
	for region in Regions.IDS:
		assert_true(menu.get_button(region).visible)
	menu.close()
	assert_false(get_tree().paused)


func test_shelf_opens_the_stock_menu_and_pauses() -> void:
	var menu: StockMenu = _cabin.get_node("StockMenu")
	assert_false(menu.is_open())
	var stock_point: InteractionArea = _cabin.get_node("Interactions/Stock")
	var player: Player = _cabin.get_node("World/Player")
	player.position = stock_point.position
	await wait_physics_frames(3)
	assert_true(stock_point.try_interact())
	assert_true(menu.is_open())
	assert_true(get_tree().paused)
	menu.close()
	assert_false(get_tree().paused)


func test_mingau_reaches_the_stock_point_walking() -> void:
	var stock_point: InteractionArea = _cabin.get_node("Interactions/Stock")
	var player: Player = _cabin.get_node("World/Player")
	player.position = Vector2(stock_point.position.x, 300)
	await wait_physics_frames(2)
	for i in 120:
		player.velocity = Vector2.UP * player.speed
		player.move_and_slide()
	await wait_physics_frames(3)
	assert_true(stock_point.try_interact(), "O gato alcança a estante pelo chão")


func test_journal_does_not_open_the_region_menu() -> void:
	var menu: RegionMenu = _cabin.get_node("RegionMenu")
	var journal: InteractionArea = _cabin.get_node("Interactions/Journal")
	var player: Player = _cabin.get_node("World/Player")
	player.position = journal.position
	await wait_physics_frames(3)
	assert_true(journal.try_interact())
	assert_false(menu.is_open())


func test_choosing_a_region_starts_floor_one_and_keeps_the_backpack() -> void:
	GameState.new_game()
	GameState.backpack.add("buriti", 2)
	GameState.stock.store("mel")
	var menu: RegionMenu = _cabin.get_node("RegionMenu")
	menu.open()
	menu.get_button(Regions.CERRADO).pressed.emit()
	# a troca de cena acontece no fim do quadro; limpa o que ela criou
	await wait_process_frames(2)
	assert_eq(GameState.current_region, "cerrado")
	assert_eq(GameState.current_floor, 1)
	assert_eq(GameState.backpack.count("buriti"), 2)
	assert_eq(GameState.stock.count("mel"), 1)
	assert_true(get_tree().current_scene is RegionFloor)
	get_tree().current_scene.queue_free()
	GameState.new_game()


func test_patient_point_opens_the_backpack_and_pauses() -> void:
	var patient_point: InteractionArea = _cabin.get_node("Interactions/Patient")
	var player: Player = _cabin.get_node("World/Player")
	player.position = patient_point.position
	await wait_physics_frames(2)
	assert_true(patient_point.try_interact())
	assert_true(get_tree().paused)
	assert_true((_cabin.get_node("BackpackMenu") as BackpackMenu).is_open())
