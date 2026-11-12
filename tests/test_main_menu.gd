extends GutTest
## Confere o menu inicial: é a cena principal do projeto, tem as cinco opções,
## Carregar Jogo só vale com save, e dá para navegar com o mouse.

const MenuScene := preload("res://scenes/ui/main_menu.tscn")
const TEST_SAVE := "user://test_menu_save.json"

var _menu: MainMenu


func before_each() -> void:
	GameState.new_game()
	_menu = _make_menu()


func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(TEST_SAVE)
	GameState.new_game()


func _make_menu() -> MainMenu:
	var menu: MainMenu = autofree(MenuScene.instantiate())
	menu.save_path = TEST_SAVE
	add_child(menu)
	return menu


func _button(button_name: String) -> Button:
	return _menu.get_node("Center/Panel/Layout/%s" % button_name)


func test_menu_is_the_main_scene() -> void:
	var main: String = ProjectSettings.get_setting("application/run/main_scene")
	assert_eq(main, ScenePaths.MENU)
	assert_true(ResourceLoader.exists(ScenePaths.MENU))


func test_has_the_five_options() -> void:
	assert_eq(_button("NewGameButton").text, "Novo Jogo")
	assert_eq(_button("LoadButton").text, "Carregar Jogo")
	assert_eq(_button("OptionsButton").text, "Opções")
	assert_eq(_button("CreditsButton").text, "Créditos")
	assert_eq(_button("QuitButton").text, "Sair")


func test_load_is_disabled_without_a_save() -> void:
	assert_false(MainMenu.has_save(TEST_SAVE))
	assert_true(_button("LoadButton").disabled)
	assert_false(_button("NewGameButton").disabled)


func test_load_is_enabled_with_a_save() -> void:
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{}")
	file.close()
	_menu = _make_menu()
	assert_true(MainMenu.has_save(TEST_SAVE))
	assert_false(_button("LoadButton").disabled)


func test_buttons_work_with_the_mouse() -> void:
	for button_name in ["NewGameButton", "LoadButton", "OptionsButton", "CreditsButton", "QuitButton"]:
		var button := _button(button_name)
		assert_eq(button.mouse_filter, Control.MOUSE_FILTER_STOP)
		assert_ne(button.focus_mode, Control.FOCUS_NONE)


func test_new_game_opens_the_cabin_with_a_clean_state() -> void:
	GameState.backpack.add("mel")
	GameState.stock.store("sardinha")
	_button("NewGameButton").pressed.emit()
	await wait_process_frames(2)
	assert_true(get_tree().current_scene is Cabin)
	assert_true(GameState.backpack.is_empty())
	assert_true(GameState.stock.is_empty())
	assert_true(
		(get_tree().current_scene as Cabin).is_in_dialogue(),
		"Novo jogo começa com a conversa introdutória"
	)
	get_tree().current_scene.queue_free()


func test_credits_opens_and_closes() -> void:
	assert_false(_menu.is_credits_open())
	_button("CreditsButton").pressed.emit()
	assert_true(_menu.is_credits_open())
	_menu.get_node("CreditsPanel/Center/Panel/Layout/BackButton").pressed.emit()
	assert_false(_menu.is_credits_open())


func test_escape_closes_the_credits() -> void:
	_button("CreditsButton").pressed.emit()
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_false(_menu.is_credits_open())


func test_quit_asks_to_leave_the_game() -> void:
	# Desliga o handler que fecha o jogo de verdade, senão o próprio teste fecharia.
	_menu.quit_requested.disconnect(_menu._quit_game)
	watch_signals(_menu)
	_button("QuitButton").pressed.emit()
	assert_signal_emitted(_menu, "quit_requested")


func test_quit_is_connected_to_closing_the_game() -> void:
	var targets := []
	for connection in _menu.quit_requested.get_connections():
		targets.append(connection["callable"].get_method())
	assert_true("_quit_game" in targets)
	_menu.quit_requested.disconnect(_menu._quit_game)


func test_new_game_has_the_initial_focus() -> void:
	assert_true(_button("NewGameButton").has_focus())


func test_options_button_opens_the_options_menu_and_focus_returns() -> void:
	var options: OptionsMenu = _menu.get_node("OptionsMenu")
	assert_false(options.is_open())
	_button("OptionsButton").pressed.emit()
	assert_true(options.is_open())
	options.close()
	assert_false(options.is_open())
	assert_true(_button("OptionsButton").has_focus())
