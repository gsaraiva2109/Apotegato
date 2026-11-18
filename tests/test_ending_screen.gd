extends GutTest
## Confere a tela de fim, aberta quando o Mingau volta para a Unifor.

const EndingScene := preload("res://scenes/ui/ending_screen.tscn")


func after_each() -> void:
	GameState.new_game()
	get_tree().paused = false


func _open() -> EndingScreen:
	var screen: EndingScreen = autofree(EndingScene.instantiate())
	add_child(screen)
	return screen


func test_count_text() -> void:
	assert_eq(EndingScreen.count_text(1), "1 paciente atendido")
	assert_eq(EndingScreen.count_text(10), "10 pacientes atendidos")


func test_shows_the_story_end_and_how_many_were_helped() -> void:
	for condition in IngredientData.get_conditions().slice(0, 4):
		GameState.patients.mark_attended(condition)
	var screen := _open()
	assert_string_contains((screen.get_node("%Story") as Label).text, "Unifor")
	assert_eq((screen.get_node("%Count") as Label).text, "4 pacientes atendidos")
	assert_string_contains((screen.get_node("%Thanks") as Label).text, "Obrigado")


func test_menu_button_has_focus() -> void:
	var screen := _open()
	var button: Button = screen.get_node("%MenuButton")
	assert_true(button.has_focus())
	assert_eq(button.text, "Voltar ao menu")


func test_unfreezes_the_game_after_the_completion() -> void:
	GameState.flow.request(GameFlow.State.DIALOGUE)
	GameState.flow.request(GameFlow.State.COMPLETION)
	assert_true(get_tree().paused)
	var screen := _open()
	assert_eq(screen.process_mode, Node.PROCESS_MODE_ALWAYS)
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))
	assert_false(get_tree().paused)
