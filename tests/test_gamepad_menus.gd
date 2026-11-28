extends GutTest
## Confere o que faz a interface funcionar só com o controle: o diário abre com o
## foco num botão, B volta no menu de pausa, a dica de pausa e o aviso de
## interação seguem o último aparelho usado, e o analógico anda o gato.

const JournalScene := preload("res://scenes/ui/journal.tscn")
const PauseMenuScene := preload("res://scenes/ui/pause_menu.tscn")
const InteractionAreaScene := preload("res://scenes/cabin/interaction_area.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")


func before_each() -> void:
	GameState.flow.reset()
	get_tree().paused = false
	InputSettings.device = InputSettings.Device.KEYBOARD


func after_each() -> void:
	GameState.flow.reset()
	get_tree().paused = false
	InputSettings.device = InputSettings.Device.KEYBOARD
	Input.action_release("move_right")


func _action_event(action: String) -> InputEventAction:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func test_the_journal_opens_with_a_focused_button() -> void:
	var journal: Node = autofree(JournalScene.instantiate())
	add_child(journal)
	journal.open()
	var focused := journal.get_viewport().gui_get_focus_owner()
	assert_not_null(focused, "Sem foco, o controle não consegue navegar")
	assert_true(focused is Button)
	assert_false((focused as Button).disabled)


func test_the_journal_focus_follows_the_page_buttons() -> void:
	var journal: Node = autofree(JournalScene.instantiate())
	add_child(journal)
	journal.open()
	var pages: Array = journal.get("_pages")
	for i in pages.size():
		journal._go_to_next_page()
	var focused := journal.get_viewport().gui_get_focus_owner() as Button
	assert_not_null(focused)
	assert_false(focused.disabled, "Na última página o foco sai do Próxima desligado")


func test_back_closes_the_pause_menu() -> void:
	var menu: PauseMenu = autofree(PauseMenuScene.instantiate())
	add_child(menu)
	menu._unhandled_input(_action_event("pause"))
	assert_true(menu.is_open())
	menu._unhandled_input(_action_event("ui_cancel"))
	assert_false(menu.is_open())
	assert_eq(GameState.flow.state, GameFlow.State.EXPLORATION)


func test_back_does_nothing_while_the_pause_menu_is_closed() -> void:
	var menu: PauseMenu = autofree(PauseMenuScene.instantiate())
	add_child(menu)
	menu._unhandled_input(_action_event("ui_cancel"))
	assert_false(menu.is_open())


func test_the_pause_hint_follows_the_device() -> void:
	var menu: PauseMenu = autofree(PauseMenuScene.instantiate())
	add_child(menu)
	var hint: Label = menu.get_node("Root/Center/Panel/Layout/MainButtons/Hint")
	assert_eq(hint.text, "Esc também continua o jogo")
	InputSettings.device = InputSettings.Device.GAMEPAD
	InputSettings.device_changed.emit()
	assert_eq(hint.text, "Start também continua o jogo")


func test_the_interaction_prompt_follows_the_device() -> void:
	var area: InteractionArea = autofree(InteractionAreaScene.instantiate())
	add_child(area)
	var prompt: Label = area.get_node("Prompt")
	assert_eq(prompt.text, "E")
	InputSettings.device = InputSettings.Device.GAMEPAD
	InputSettings.device_changed.emit()
	assert_eq(prompt.text, "A")
	InputSettings.device = InputSettings.Device.KEYBOARD
	InputSettings.device_changed.emit()
	assert_eq(prompt.text, "E")


func test_a_half_pushed_stick_walks_slower() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	add_child(player)
	Input.action_press("move_right", 0.5)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	assert_gt(direction.x, 0.0)
	assert_lt(player.velocity_for(direction).length(), player.speed)
	Input.action_release("move_right")
	Input.action_press("move_right", 1.0)
	direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	assert_almost_eq(player.velocity_for(direction).length(), player.speed, 0.01)
