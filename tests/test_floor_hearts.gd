extends GutTest
## Confere os corações no andar: HUD no canto superior esquerdo e o desmaio, que
## leva à cabana com a mochila e o estoque intactos.

const FloorScene := preload("res://scenes/region/floor.tscn")

var _floor: RegionFloor


func before_each() -> void:
	GameState.new_game()
	GameState.start_region(Regions.CAATINGA)
	_floor = autofree(FloorScene.instantiate())
	_floor.faint_seconds = 0.05
	add_child(_floor)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	GameState.new_game()


func _player() -> Player:
	return _floor.get_node("World/Player")


func _hud() -> Hud:
	return _floor.get_node("Hud")


func test_hud_shows_seven_full_hearts_in_the_top_left_corner() -> void:
	var box: HBoxContainer = _hud().get_node("Root/HeartsBox")
	assert_eq(box.get_child_count(), 7)
	assert_eq(_hud().full_hearts(), 7)
	assert_lt(box.global_position.x, 40.0)
	assert_lt(box.global_position.y, 40.0)


func test_hud_follows_the_hearts() -> void:
	_player().take_hit()
	assert_eq(_hud().full_hearts(), 6)
	assert_eq(_hud().get_node("Root/HeartsBox").get_child_count(), 7, "Os vazios continuam na tela")
	_player().heal()
	assert_eq(_hud().full_hearts(), 7)


func test_fainting_returns_to_the_cabin_with_the_backpack_intact() -> void:
	GameState.backpack.add("licuri", 2)
	GameState.backpack.add("mel")
	GameState.stock.store("sardinha", 3)
	_player().invulnerability_time = 0.0
	for i in 7:
		_player().take_hit()
	var message: Label = _hud().get_node("Root/MessageLabel")
	assert_true(message.visible)
	await wait_seconds(0.3)
	assert_true(get_tree().current_scene is Cabin, "Acordou na cabana")
	assert_eq(GameState.current_region, "")
	assert_eq(GameState.backpack.count("licuri"), 2)
	assert_eq(GameState.backpack.count("mel"), 1)
	assert_eq(GameState.backpack.used_slots(), 2)
	assert_eq(GameState.stock.count("sardinha"), 3)
	get_tree().current_scene.queue_free()


func test_fainting_with_a_menu_open_does_not_leave_the_cabin_paused() -> void:
	_player().invulnerability_time = 0.0
	get_tree().paused = true
	_floor._door_menu.open(1)
	for i in 7:
		_player().take_hit()
	await wait_seconds(0.3)
	assert_true(get_tree().current_scene is Cabin, "Acordou na cabana")
	assert_false(get_tree().paused, "A cabana não pode herdar a pausa do menu")
	get_tree().current_scene.queue_free()


func test_hearts_are_back_to_seven_when_the_cat_returns_to_a_region() -> void:
	_player().invulnerability_time = 0.0
	for i in 3:
		_player().take_hit()
	_floor._on_door_choice_made(DoorMenu.CABIN)
	await wait_process_frames(2)
	get_tree().current_scene.queue_free()
	GameState.start_region(Regions.CERRADO)
	var again: RegionFloor = autofree(FloorScene.instantiate())
	add_child(again)
	assert_eq((again.get_node("World/Player") as Player).hearts.current, 7)


func test_hearts_survive_going_up_a_floor() -> void:
	_player().take_hit()
	_floor._on_door_choice_made(DoorMenu.UP)
	assert_eq(_player().hearts.current, 6)
	assert_eq(_hud().full_hearts(), 6)


func test_creature_touching_the_cat_in_the_floor_hurts() -> void:
	var creature := _floor.get_creatures()[0]
	creature.global_position = _player().global_position + Vector2(20, 0)
	await wait_physics_frames(4)
	assert_eq(_player().hearts.current, 6)
	assert_eq(_hud().full_hearts(), 6)
