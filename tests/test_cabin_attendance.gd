extends GutTest
## Confere o atendimento na cabana de ponta a ponta, seguindo o roteiro: a
## introdução automática, o lembrete, a queixa, o pedido, as entregas, a saída do
## paciente e o encerramento da campanha.

const CabinScene := preload("res://scenes/cabin/cabin.tscn")

var _cabin: Cabin


func after_each() -> void:
	GameState.new_game()
	get_tree().paused = false


## Abre a cabana. Sem `condition`, é a primeira visita (com a introdução).
func _open_cabin(condition: String = "", phase := Attendance.Phase.ARRIVED) -> void:
	if not condition.is_empty():
		GameState.attendance.intro_done = true
		GameState.attendance.arrive(condition)
		GameState.attendance.phase = phase
	_cabin = CabinScene.instantiate()
	_cabin.animate_patient = false
	autofree(_cabin)
	add_child(_cabin)
	_box().characters_per_second = 0.0


func _box() -> DialogueBox:
	return _cabin.get_node("DialogueBox")


func _backpack() -> BackpackMenu:
	return _cabin.get_node("BackpackMenu")


## Avança a conversa até o fim (ou até as escolhas). Devolve os textos vistos.
func _read_dialogue() -> PackedStringArray:
	var seen := PackedStringArray()
	var guard := 0
	while _box().is_open() and guard < 200:
		if not _box().is_page_complete():
			_box().advance()
		seen.append("%s: %s" % [_box().current_speaker(), _box().current_text()])
		if _box().is_choosing():
			break
		_box().advance()
		guard += 1
	return seen


func _texts_contain(texts: PackedStringArray, part: String) -> bool:
	for text in texts:
		if text.contains(part):
			return true
	return false


func _requirement_ids(condition: String) -> Array[String]:
	var ids: Array[String] = []
	for group in IngredientData.get_requirements(condition):
		ids.append(group[0])
	return ids


func test_intro_starts_by_itself_on_the_first_visit_and_freezes_the_cat() -> void:
	GameState.new_game()
	_open_cabin()
	assert_true(_box().is_open(), "A conversa começa sem apertar nada")
	assert_eq(_box().current_speaker(), "Apotecária")
	assert_string_starts_with(_box().current_text(), "Olá, gatinho.")
	assert_true(GameState.flow.is_in(GameFlow.State.DIALOGUE))
	assert_true(get_tree().paused, "O gato e as criaturas ficam parados")
	var apothecary: InteractionArea = _cabin.get_node("Interactions/Apothecary")
	assert_false(apothecary.try_interact(), "Nenhuma outra interação durante a conversa")
	var texts := _read_dialogue()
	assert_true(texts[-1].begins_with("Mingau: Certo!"), "Termina com a última fala do Mingau")


func test_first_patient_arrives_right_after_the_intro() -> void:
	GameState.new_game()
	_open_cabin()
	watch_signals(_cabin)
	_read_dialogue()
	assert_true(GameState.attendance.intro_done)
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))
	assert_false(get_tree().paused)
	assert_eq(GameState.attendance.phase, Attendance.Phase.ARRIVED)
	assert_true(_cabin.get_patient().visible)
	assert_signal_emitted(_cabin, "patient_arrived")


func test_intro_does_not_repeat_on_the_next_visit() -> void:
	GameState.new_game()
	GameState.attendance.finish_intro()
	_open_cabin()
	assert_false(_box().is_open())
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))


func test_apothecary_reminds_before_mingau_hears_the_patient() -> void:
	_open_cabin("gastrite")
	_cabin._on_interacted(&"apothecary")
	assert_true(_box().is_open())
	assert_string_contains(_box().current_text(), "Temos um paciente.")
	_read_dialogue()
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))
	assert_eq(GameState.attendance.phase, Attendance.Phase.ARRIVED)


func test_patient_tells_the_complaint_with_the_cast_name() -> void:
	_open_cabin("anemia_ferropriva")
	_cabin._on_interacted(&"patient")
	assert_eq(_box().current_speaker(), "Joaquim")
	assert_string_starts_with(_box().current_text(), "Tenho me sentido muito cansado")
	_read_dialogue()
	assert_eq(GameState.attendance.phase, Attendance.Phase.HEARD)


func test_apothecary_requests_the_ingredients_after_the_complaint() -> void:
	_open_cabin("diarreia", Attendance.Phase.HEARD)
	_cabin._on_interacted(&"apothecary")
	assert_string_contains(_box().current_text(), "Água de Coco")
	_read_dialogue()
	assert_eq(GameState.attendance.phase, Attendance.Phase.REQUESTED)
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))


func test_after_the_request_the_apothecary_opens_the_delivery() -> void:
	_open_cabin("diarreia", Attendance.Phase.REQUESTED)
	_cabin._on_interacted(&"apothecary")
	assert_true(_backpack().is_open())
	assert_eq(_backpack().condition, "diarreia")
	assert_true(GameState.flow.is_in(GameFlow.State.DELIVERY))
	assert_true(get_tree().paused, "O gato não anda durante a entrega")
	_backpack().close()
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))


func test_empty_backpack_gets_the_empty_dialogue_and_returns_to_the_backpack() -> void:
	_open_cabin("insonia", Attendance.Phase.REQUESTED)
	_cabin.open_backpack()
	_backpack().deliver()
	assert_true(GameState.flow.is_in(GameFlow.State.DIALOGUE))
	assert_eq(_box().current_speaker(), "Mingau")
	assert_eq(_box().current_text(), "Ainda não encontrei nenhum ingrediente.")
	_read_dialogue()
	assert_true(GameState.flow.is_in(GameFlow.State.DELIVERY), "Volta para a mochila aberta")
	assert_true(_backpack().is_open())


func test_partial_delivery_lists_what_is_missing() -> void:
	_open_cabin("anemia_ferropriva", Attendance.Phase.REQUESTED)
	GameState.backpack.add("figado_bovino")
	_cabin.open_backpack()
	_backpack().deliver()
	var texts := _read_dialogue()
	assert_true(_texts_contain(texts, "Trouxe o que consegui encontrar por enquanto."))
	assert_true(
		_texts_contain(texts, "Ainda faltam: Castanha de caju e Camu-camu ou Acerola."),
		"Lista os que faltam, com a regra ou: %s" % [texts]
	)
	assert_eq(GameState.attendance.phase, Attendance.Phase.REQUESTED)


func test_extras_get_the_stock_dialogue() -> void:
	_open_cabin("insonia", Attendance.Phase.REQUESTED)
	GameState.backpack.add("sardinha")
	_cabin.open_backpack()
	_backpack().deliver()
	var texts := _read_dialogue()
	assert_true(_texts_contain(texts, "não são necessários para o paciente atual"))
	assert_false(_texts_contain(texts, "Ainda faltam"), "Nada útil entregue: só a fala do estoque")


func test_complete_delivery_ends_the_attendance_and_calls_the_next_patient() -> void:
	_open_cabin("queimaduras", Attendance.Phase.REQUESTED)
	for id in _requirement_ids("queimaduras"):
		GameState.backpack.add(id)
	watch_signals(_cabin)
	_cabin.open_backpack()
	_backpack().deliver()
	var texts := _read_dialogue()
	assert_true(_texts_contain(texts, "Apotecária: A Pele de Tilápia"), "Orientação")
	assert_true(
		texts[-1].begins_with("Expedito: Obrigado por me ajudar"), "Agradecimento por último"
	)
	assert_true(GameState.patients.is_attended("queimaduras"))
	assert_signal_emitted_with_parameters(_cabin, "patient_left", ["queimaduras"])
	assert_false(_backpack().is_open(), "Sem sobras, a mochila fecha")
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))
	assert_eq(GameState.attendance.phase, Attendance.Phase.ARRIVED, "O próximo paciente entrou")
	assert_ne(GameState.attendance.condition, "queimaduras")


func test_complete_delivery_with_extras_keeps_the_backpack_for_them() -> void:
	_open_cabin("queimaduras", Attendance.Phase.REQUESTED)
	for id in _requirement_ids("queimaduras"):
		GameState.backpack.add(id)
	GameState.backpack.add("pequi")
	_cabin.open_backpack()
	_backpack().deliver()
	_read_dialogue()
	assert_true(_backpack().is_open(), "Fica aberta para guardar ou usar as sobras")
	assert_true(GameState.flow.is_in(GameFlow.State.DELIVERY))
	var deliver_button: Button = _backpack().get_node(
		"Root/Center/Panel/Layout/Buttons/DeliverButton"
	)
	assert_true(deliver_button.disabled, "Não entrega de novo")
	assert_null(_backpack().deliver())
	_backpack().close()
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))


func test_ending_comes_after_the_last_attendance_and_keep_helping_continues() -> void:
	var last := "xeroftalmia"
	for condition in IngredientData.get_conditions():
		if condition != last:
			GameState.patients.mark_attended(condition)
	_open_cabin(last, Attendance.Phase.REQUESTED)
	for id in _requirement_ids(last):
		GameState.backpack.add(id)
	_cabin.open_backpack()
	_backpack().deliver()
	var texts := _read_dialogue()
	assert_true(_box().is_choosing(), "Encerramento com a escolha: %s" % [texts[-1]])
	assert_true(_texts_contain(texts, "Você ajudou todos os pacientes"))
	_box().choose(Attendance.CHOICE_KEEP_HELPING)
	texts = _read_dialogue()
	assert_true(texts[-1].ends_with("Pode contar comigo!"))
	assert_true(GameState.attendance.continuous)
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))
	assert_eq(GameState.attendance.phase, Attendance.Phase.ARRIVED, "Modo contínuo: novo paciente")


func test_going_home_completes_the_campaign() -> void:
	for condition in IngredientData.get_conditions():
		GameState.patients.mark_attended(condition)
	GameState.attendance.intro_done = true
	_open_cabin()
	_cabin.ending_seconds = 60.0
	assert_true(_box().is_open(), "Sem pacientes pendentes, o encerramento toca ao abrir a cabana")
	_read_dialogue()
	_box().choose(Attendance.CHOICE_GO_HOME)
	var texts := _read_dialogue()
	assert_true(texts[-1].ends_with("Boa viagem!"))
	assert_true(GameState.flow.is_in(GameFlow.State.COMPLETION))
	assert_true(get_tree().paused)
