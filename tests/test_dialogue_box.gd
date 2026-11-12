extends GutTest
## Confere a caixa de diálogo: nome e texto, o texto aparecendo e avançando com
## E, as páginas de falas longas e as escolhas.

const BoxScene := preload("res://scenes/ui/dialogue_box.tscn")

var _box: DialogueBox


func before_each() -> void:
	_box = autofree(BoxScene.instantiate())
	add_child(_box)


func _lines(texts: Array, speaker_name: String = "Apotecária") -> Array[DialogueLine]:
	var lines: Array[DialogueLine] = []
	for text: String in texts:
		lines.append(DialogueLine.new("apothecary", speaker_name, text))
	return lines


func _press(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func test_starts_closed() -> void:
	assert_false(_box.is_open())
	assert_false(_box.visible)


func test_shows_the_speaker_name_and_the_text() -> void:
	_box.play(_lines(["Olá, gatinho."]))
	assert_true(_box.is_open())
	assert_true(_box.visible)
	assert_eq(_box.current_speaker(), "Apotecária")
	assert_eq(_box.current_text(), "Olá, gatinho.")


func test_box_sits_at_the_bottom_of_the_screen() -> void:
	_box.play(_lines(["Olá."]))
	var panel: Control = _box.get_node("Root/Box")
	var screen := _box.get_viewport().get_visible_rect().size
	assert_gt(panel.get_global_rect().position.y, screen.y * 0.6)
	assert_almost_eq(panel.get_global_rect().end.y, screen.y - 16.0, 1.0)


func test_first_press_completes_the_line_and_the_second_advances() -> void:
	_box.characters_per_second = 10.0
	_box.play(_lines(["Primeira fala, bem comprida.", "Segunda fala."]))
	assert_false(_box.is_page_complete(), "O texto aparece aos poucos")
	_box.advance()
	assert_true(_box.is_page_complete(), "O primeiro E mostra a fala inteira")
	assert_eq(_box.current_text(), "Primeira fala, bem comprida.")
	_box.advance()
	assert_eq(_box.current_text(), "Segunda fala.")


func test_text_appears_over_time() -> void:
	_box.characters_per_second = 1000.0
	_box.play(_lines(["Texto curto."]))
	await wait_process_frames(3)
	assert_true(_box.is_page_complete())


func test_last_line_closes_and_emits_finished() -> void:
	_box.characters_per_second = 0.0
	watch_signals(_box)
	_box.play(_lines(["Uma.", "Duas."]))
	_box.advance()
	assert_signal_not_emitted(_box, "finished")
	_box.advance()
	assert_false(_box.is_open())
	assert_signal_emitted_with_parameters(_box, "finished", [""])


func test_interact_key_advances_and_is_consumed() -> void:
	_box.characters_per_second = 0.0
	watch_signals(_box)
	_box.play(_lines(["Uma."]))
	_press(&"interact")
	await wait_process_frames(1)
	assert_signal_emitted(_box, "finished")


func test_markers_are_replaced() -> void:
	_box.characters_per_second = 0.0
	var lines := _lines(["Ainda faltam: {missing}."])
	_box.play(lines, {"missing": "Mel e Pequi"})
	assert_eq(_box.current_text(), "Ainda faltam: Mel e Pequi.")


func test_long_lines_are_split_into_pages_that_fit() -> void:
	_box.characters_per_second = 0.0
	var guidance: String = DialogueData.get_lines("guidance", "diarreia")[0].text
	_box.play(_lines([guidance]))
	assert_gt(_box.page_count(), 1, "A orientação longa vira mais de uma página")
	var joined := PackedStringArray()
	var label: Label = _box.get_node("Root/Text")
	for i in _box.page_count():
		assert_lte(label.get_line_count(), _box.max_lines, "Página %d cabe na caixa" % i)
		joined.append(_box.current_text())
		if i < _box.page_count() - 1:
			_box.advance()
	assert_eq(" ".join(joined), guidance, "Nenhuma palavra se perde entre as páginas")


func test_choices_appear_on_the_last_line_and_return_the_id() -> void:
	_box.characters_per_second = 0.0
	var lines := _lines(["Você quer voltar?"])
	lines[0].choices = [
		{"id": "go_home", "text": "Voltar para a Unifor"},
		{"id": "keep_helping", "text": "Continuar ajudando"},
	]
	watch_signals(_box)
	_box.play(lines)
	assert_true(_box.is_choosing())
	var buttons := _box.choice_buttons()
	assert_eq(buttons.size(), 2)
	assert_eq(buttons[0].text, "Voltar para a Unifor")
	assert_true(buttons[0].has_focus())
	_box.advance()
	assert_true(_box.is_open(), "Com escolhas, avançar não fecha")
	buttons[1].pressed.emit()
	assert_false(_box.is_open())
	assert_signal_emitted_with_parameters(_box, "finished", ["keep_helping"])


func test_line_started_reports_each_line() -> void:
	_box.characters_per_second = 0.0
	watch_signals(_box)
	_box.play(_lines(["Uma.", "Duas."]))
	assert_signal_emitted_with_parameters(_box, "line_started", [0])
	_box.advance()
	assert_signal_emitted_with_parameters(_box, "line_started", [1])


func test_works_while_the_game_is_frozen() -> void:
	assert_eq(_box.process_mode, Node.PROCESS_MODE_ALWAYS)
