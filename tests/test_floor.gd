extends GutTest
## Confere o andar jogável: gera a região e o andar do GameState, mostra região
## e andar, e a porta leva à subida de andar ou à troca de região sem perder a
## mochila nem o estoque.

const FloorScene := preload("res://scenes/region/floor.tscn")

var _floor: RegionFloor


func before_each() -> void:
	GameState.new_game()
	GameState.attendance.intro_done = true
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


func _door() -> InteractionArea:
	return _floor.get_node("World/ExitDoor")


func _label() -> Label:
	return _floor.get_node("Hud/Root/LocationPanel/LocationLabel")


func _door_menu() -> DoorMenu:
	return _floor.get_node("DoorMenu")


func _region_menu() -> RegionMenu:
	return _floor.get_node("RegionMenu")


func test_generates_the_floor_of_the_current_region() -> void:
	var tiles: TileMapLayer = _room().get_node("Tiles")
	var source: TileSetAtlasSource = tiles.tile_set.get_source(RegionTileSet.SOURCE_ID)
	assert_eq(source.texture.resource_path, Regions.tileset_path("caatinga"))
	assert_eq(tiles.get_used_rect(), Rect2i(0, 0, 30, 17))


func test_player_starts_on_the_entry_and_door_is_on_the_exit() -> void:
	var layout := _room().layout
	assert_eq(_player().position, MazeGrid.cell_to_position(layout.entry_cell))
	assert_eq(_door().position, MazeGrid.cell_to_position(layout.exit_cell))


func test_camera_is_limited_to_the_floor() -> void:
	var camera: Camera2D = _player().get_node("Camera")
	assert_eq(camera.limit_right, 960)
	assert_eq(camera.limit_bottom, 544)


func test_shows_region_and_floor_on_screen() -> void:
	assert_eq(_label().text, "Caatinga - Andar 1")


func test_opens_directly_with_a_default_region() -> void:
	GameState.new_game()
	var direct: RegionFloor = autofree(FloorScene.instantiate())
	add_child(direct)
	assert_eq(GameState.current_region, RegionFloor.DEFAULT_REGION)


func test_door_interaction_opens_the_menu_and_pauses() -> void:
	_player().position = _door().position
	await wait_physics_frames(3)
	assert_true(_door().is_prompt_visible())
	assert_true(_door().try_interact())
	assert_true(_door_menu().is_open())
	assert_true(get_tree().paused)
	_door_menu().close()
	assert_false(get_tree().paused, "Fechar o menu volta ao jogo")


func test_going_up_generates_a_new_floor_with_the_other_parity() -> void:
	var before := _room().layout
	_door_menu().open(1)
	_door_menu().choice_made.emit(DoorMenu.UP)
	assert_eq(GameState.current_floor, 2)
	assert_eq(GameState.floor_parity(), "par")
	assert_ne(_room().layout, before, "Andar novo, mapa novo")
	assert_eq(_label().text, "Caatinga - Andar 2")
	assert_eq(_player().position, MazeGrid.cell_to_position(_room().layout.entry_cell))


func test_other_region_goes_to_floor_one_keeping_backpack_and_stock() -> void:
	GameState.backpack.add("acerola", 2)
	GameState.stock.store("mel")
	_floor._on_door_choice_made(DoorMenu.UP)
	_floor._on_door_choice_made(DoorMenu.OTHER_REGION)
	assert_true(_region_menu().is_open())
	assert_false(_region_menu().get_button("caatinga").visible, "Outra região, não a atual")
	_region_menu().get_button(Regions.LITORAL).pressed.emit()
	assert_eq(GameState.current_region, "litoral")
	assert_eq(GameState.current_floor, 1)
	assert_eq(_label().text, "Litoral - Andar 1")
	assert_eq(GameState.backpack.count("acerola"), 2)
	assert_eq(GameState.stock.count("mel"), 1)
	assert_false(get_tree().paused)


func test_cancelling_the_door_menu_keeps_the_floor() -> void:
	var before := _room().layout
	_door_menu().open(1)
	get_tree().paused = true
	_door_menu().close()
	assert_same(_room().layout, before)
	assert_eq(GameState.current_floor, 1)


func test_back_to_the_cabin_keeps_backpack_and_stock() -> void:
	GameState.backpack.add("licuri")
	GameState.stock.store("sardinha", 3)
	_floor._on_door_choice_made(DoorMenu.CABIN)
	# a troca de cena acontece no fim do quadro; limpa o que ela criou
	await wait_process_frames(2)
	assert_eq(GameState.current_region, "")
	assert_eq(GameState.backpack.count("licuri"), 1)
	assert_eq(GameState.stock.count("sardinha"), 3)
	assert_true(get_tree().current_scene is Cabin)
	get_tree().current_scene.queue_free()
