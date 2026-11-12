extends GutTest
## Confere o menu de pausa: Esc abre e fecha na exploração, o jogo congela e
## retoma, a pausa é recusada em diálogo, entrega e outros menus, as opções
## abrem e voltam, e voltar ao menu inicial pede confirmação.

const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")

var _menu: PauseMenu


func before_each() -> void:
	GameState.flow.reset()
	get_tree().paused = false
	_menu = autofree(PauseMenuScene.instantiate())
	add_child(_menu)


func after_each() -> void:
	GameState.flow.reset()
	get_tree().paused = false


func _key(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	_menu._unhandled_input(event)


func _button(path: String) -> Button:
	return _menu.get_node("Root/Center/Panel/Layout/%s" % path)


func test_starts_closed() -> void:
	assert_false(_menu.is_open())


func test_pause_key_opens_and_freezes_the_game() -> void:
	_key("pause")
	assert_true(_menu.is_open())
	assert_eq(GameState.flow.state, GameFlow.State.MENU)
	assert_true(get_tree().paused)
	assert_true(_button("MainButtons/ResumeButton").has_focus())


func test_pause_key_again_resumes() -> void:
	_key("pause")
	_key("pause")
	assert_false(_menu.is_open())
	assert_eq(GameState.flow.state, GameFlow.State.EXPLORATION)
	assert_false(get_tree().paused)


func test_continue_button_resumes_and_emits() -> void:
	watch_signals(_menu)
	_key("pause")
	_button("MainButtons/ResumeButton").pressed.emit()
	assert_false(_menu.is_open())
	assert_false(get_tree().paused)
	assert_signal_emitted(_menu, "opened")
	assert_signal_emitted(_menu, "resumed")


func test_pause_is_refused_outside_exploration() -> void:
	for state in [GameFlow.State.DIALOGUE, GameFlow.State.DELIVERY]:
		GameState.flow.reset()
		assert_true(GameState.flow.request(GameFlow.State.DIALOGUE))
		if state == GameFlow.State.DELIVERY:
			assert_true(GameState.flow.request(GameFlow.State.DELIVERY))
		_key("pause")
		assert_false(_menu.is_open(), "Não pausa durante o estado %d" % state)
		assert_eq(GameState.flow.state, state)


func test_pause_is_refused_while_another_menu_is_open() -> void:
	assert_true(GameState.flow.open_menu())
	_key("pause")
	assert_false(_menu.is_open())
	assert_eq(GameState.flow.state, GameFlow.State.MENU)


func test_options_open_and_return_to_the_pause_panel() -> void:
	_key("pause")
	var options: OptionsMenu = _menu.get_node("OptionsMenu")
	_button("MainButtons/OptionsButton").pressed.emit()
	assert_true(options.is_open())
	assert_false((_menu.get_node("Root/Center") as Control).visible)
	assert_true(_menu.is_open(), "Continua pausado atrás das opções")
	options.close()
	assert_true((_menu.get_node("Root/Center") as Control).visible)
	assert_true(_button("MainButtons/OptionsButton").has_focus())
	assert_eq(GameState.flow.state, GameFlow.State.MENU)


func test_pause_key_does_not_resume_while_options_are_open() -> void:
	_key("pause")
	_button("MainButtons/OptionsButton").pressed.emit()
	_key("pause")
	assert_true(_menu.is_open())


func test_leaving_asks_for_confirmation_and_can_be_cancelled() -> void:
	_key("pause")
	_button("MainButtons/MenuButton").pressed.emit()
	assert_true((_menu.get_node("Root/Center/Panel/Layout/ConfirmBox") as Control).visible)
	assert_false((_menu.get_node("Root/Center/Panel/Layout/MainButtons") as Control).visible)
	assert_true(_button("ConfirmBox/NoButton").has_focus())
	_button("ConfirmBox/NoButton").pressed.emit()
	assert_true((_menu.get_node("Root/Center/Panel/Layout/MainButtons") as Control).visible)
	assert_true(_menu.is_open())


func test_pause_key_cancels_the_confirmation_before_resuming() -> void:
	_key("pause")
	_button("MainButtons/MenuButton").pressed.emit()
	_key("pause")
	assert_true(_menu.is_open())
	assert_false((_menu.get_node("Root/Center/Panel/Layout/ConfirmBox") as Control).visible)
	_key("pause")
	assert_false(_menu.is_open())


func test_reopening_starts_on_the_main_buttons() -> void:
	_key("pause")
	_button("MainButtons/MenuButton").pressed.emit()
	_menu.resume()
	_key("pause")
	assert_true((_menu.get_node("Root/Center/Panel/Layout/MainButtons") as Control).visible)
	assert_false((_menu.get_node("Root/Center/Panel/Layout/ConfirmBox") as Control).visible)


func test_cabin_and_floor_have_a_pause_menu() -> void:
	for path in [ScenePaths.CABIN, ScenePaths.FLOOR]:
		var scene: Node = autofree((load(path) as PackedScene).instantiate())
		assert_not_null(scene.get_node_or_null("PauseMenu"), path)


func test_cabin_pause_is_refused_during_the_intro_and_works_after() -> void:
	GameState.new_game()
	var cabin: Cabin = autofree((load(ScenePaths.CABIN) as PackedScene).instantiate())
	cabin.animate_patient = false
	add_child(cabin)
	var pause_menu: PauseMenu = cabin.get_node("PauseMenu")
	assert_eq(GameState.flow.state, GameFlow.State.DIALOGUE, "A cabana abre com a introdução")
	assert_false(pause_menu.pause())
	assert_false(get_tree().paused and pause_menu.is_open())
	GameState.flow.reset()
	assert_true(pause_menu.pause())
	assert_true(get_tree().paused)
	pause_menu.resume()
	assert_false(get_tree().paused)
	GameState.new_game()
