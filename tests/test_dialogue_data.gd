extends GutTest
## Confere o data/dialogos.json (conversas gerais) e o leitor DialogueData: as
## conversas que o atendimento usa existem, os falantes são válidos, nenhuma fala
## está vazia e as escolhas do encerramento estão completas.

const DIALOGUES_PATH := "res://data/dialogos.json"

## Todas as conversas gerais que o atendimento toca.
const REQUIRED := [
	Attendance.INTRO,
	Attendance.PATIENT_REMINDER,
	Attendance.DELIVERY_PARTIAL,
	Attendance.DELIVERY_EXTRAS,
	Attendance.DELIVERY_EMPTY,
	Attendance.ENDING,
	Attendance.ENDING_GO_HOME,
	Attendance.ENDING_KEEP_HELPING,
]


func test_file_has_every_conversation_the_attendance_uses() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIALOGUES_PATH))
	assert_true(data.has("conversations"))
	for id in REQUIRED:
		assert_true(data["conversations"].has(id), "falta a conversa %s" % id)
		assert_true(DialogueData.has_conversation(id))


func test_lines_have_valid_speakers_and_text() -> void:
	for id in DialogueData.get_conversation_ids():
		var lines := DialogueData.get_conversation(id)
		assert_gt(lines.size(), 0, "conversa vazia: %s" % id)
		for line in lines:
			assert_true(line.speaker in DialogueData.SPEAKERS, "falante inválido em %s" % id)
			assert_false(line.text.strip_edges().is_empty(), "fala vazia em %s" % id)
			assert_false(line.speaker_name.is_empty())


func test_only_the_ending_question_has_choices() -> void:
	for id in DialogueData.get_conversation_ids():
		var lines := DialogueData.get_conversation(id)
		for i in lines.size():
			var is_question := id == Attendance.ENDING and i == lines.size() - 1
			assert_eq(lines[i].has_choices(), is_question, "escolhas em %s, fala %d" % [id, i])


func test_ending_offers_going_home_or_keeping_helping() -> void:
	var question: DialogueLine = DialogueData.get_conversation(Attendance.ENDING)[-1]
	var ids: Array[String] = []
	for choice in question.choices:
		ids.append(choice["id"])
		assert_false(str(choice["text"]).is_empty())
	assert_eq(ids, [Attendance.CHOICE_GO_HOME, Attendance.CHOICE_KEEP_HELPING] as Array[String])
	assert_eq(question.choices[0]["text"], "Voltar para a Unifor")
	assert_eq(question.choices[1]["text"], "Continuar ajudando")


func test_partial_delivery_has_the_missing_marker() -> void:
	var text := ""
	for line in DialogueData.get_conversation(Attendance.DELIVERY_PARTIAL):
		text += line.text
	assert_string_contains(text, "{missing}")


func test_intro_starts_with_the_apothecary_and_ends_with_mingau() -> void:
	var lines := DialogueData.get_conversation(Attendance.INTRO)
	assert_eq(lines[0].speaker, DialogueData.SPEAKER_APOTHECARY)
	assert_eq(lines[-1].speaker, DialogueData.SPEAKER_MINGAU)
	assert_eq(lines[0].speaker_name, "Apotecária")
	assert_eq(lines[-1].speaker_name, "Mingau")


func test_condition_parts_come_from_the_treatments_file() -> void:
	for condition in IngredientData.get_conditions():
		for part in DialogueData.CONDITION_PARTS:
			assert_true(
				DialogueData.has_condition_part(condition, part), "%s/%s" % [condition, part]
			)
			assert_gt(DialogueData.get_lines(part, condition).size(), 0)


func test_patient_speaks_with_the_cast_name() -> void:
	var complaint := DialogueData.get_lines(Attendance.COMPLAINT, "anemia_ferropriva")
	assert_eq(complaint[0].speaker, DialogueData.SPEAKER_PATIENT)
	assert_eq(complaint[0].speaker_name, "Joaquim")
	assert_eq(DialogueData.speaker_name("patient", "condicao_inexistente"), "Paciente")


func test_unknown_conversation_falls_back_without_breaking() -> void:
	var lines := DialogueData.get_conversation("nao_existe")
	assert_eq(lines.size(), 1)
	assert_eq(lines[0].text, DialogueData.MISSING_TEXT)
