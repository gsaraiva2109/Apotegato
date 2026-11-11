extends GutTest
## Confere o data/dialogos.json: as falas do roteiro das 10 condições, os
## diálogos de entrega e o encerramento.

const DIALOGUES_PATH := "res://data/dialogos.json"
const SPEAKERS := ["apothecary", "mingau", "patient"]
const CONDITION_STEPS := [
	"patient_intro", "apothecary_request", "apothecary_guidance", "patient_thanks"
]
## Palavras que mostram a recomendação de procurar atendimento de saúde.
const HEALTH_ADVICE := ["médic", "profissional de saúde", "consulta", "avaliação", "atendimento"]

var _data: Dictionary


func before_each() -> void:
	var file := FileAccess.open(DIALOGUES_PATH, FileAccess.READ)
	_data = JSON.parse_string(file.get_as_text())


func _assert_lines(lines: Array, label: String) -> void:
	assert_gt(lines.size(), 0, "sem falas em %s" % label)
	for line: Dictionary in lines:
		assert_true(line["speaker"] in SPEAKERS, "falante inválido em %s" % label)
		assert_false(str(line["text"]).strip_edges().is_empty(), "fala vazia em %s" % label)


func _guidance_text(condition: String) -> String:
	var steps: Dictionary = _data["conditions"][condition]
	var text := ""
	for step in ["apothecary_request", "apothecary_guidance"]:
		for line: Dictionary in steps[step]:
			text += line["text"] + " "
	return text


func test_every_condition_has_the_four_steps() -> void:
	var conditions: Dictionary = _data["conditions"]
	assert_eq(conditions.size(), 10)
	for condition in IngredientData.get_conditions():
		assert_true(conditions.has(condition), "sem diálogo para %s" % condition)
		for step in CONDITION_STEPS:
			assert_true(conditions[condition].has(step), "%s sem %s" % [condition, step])
			_assert_lines(conditions[condition][step], "%s/%s" % [condition, step])


func test_speakers_match_each_step() -> void:
	for condition: String in _data["conditions"]:
		var steps: Dictionary = _data["conditions"][condition]
		for step in ["patient_intro", "patient_thanks"]:
			for line: Dictionary in steps[step]:
				assert_eq(line["speaker"], "patient", "%s/%s" % [condition, step])
		for step in ["apothecary_request", "apothecary_guidance"]:
			for line: Dictionary in steps[step]:
				assert_eq(line["speaker"], "apothecary", "%s/%s" % [condition, step])


func test_every_condition_recommends_seeking_care() -> void:
	for condition: String in _data["conditions"]:
		var text := _guidance_text(condition).to_lower()
		var found := false
		for word in HEALTH_ADVICE:
			if text.contains(word):
				found = true
		assert_true(found, "%s sem recomendação de procurar atendimento" % condition)


func test_request_names_every_required_ingredient() -> void:
	for condition: String in _data["conditions"]:
		var text: String = _data["conditions"][condition]["apothecary_request"][0]["text"]
		for requirement in IngredientData.get_requirements(condition):
			var named := false
			for ingredient in requirement:
				var ingredient_name := _plain(
					IngredientData.get_ingredient(ingredient).display_name
				)
				if _plain(text).contains(ingredient_name):
					named = true
			assert_true(named, "pedido de %s não cita %s" % [condition, requirement])


## Compara nomes sem diferença de maiúsculas e de hífen ("Camu-camu" e "Camu-Camu").
func _plain(text: String) -> String:
	return text.to_lower().replace("-", " ")


func test_delivery_dialogues() -> void:
	var delivery: Dictionary = _data["delivery"]
	for key in ["partial", "surplus", "empty_backpack"]:
		_assert_lines(delivery[key], "delivery/%s" % key)
	var partial_text := ""
	for line: Dictionary in delivery["partial"]:
		partial_text += line["text"]
	assert_true(partial_text.contains("{lista}"), "a entrega parcial precisa listar o que falta")


func test_intro_and_reminder() -> void:
	_assert_lines(_data["intro"], "intro")
	_assert_lines(_data["first_visit_reminder"], "first_visit_reminder")
	assert_eq(_data["intro"][0]["speaker"], "apothecary")
	assert_eq(_data["intro"][-1]["speaker"], "mingau")


func test_ending() -> void:
	var ending: Dictionary = _data["ending"]
	for key in ["lines", "go_home", "keep_helping"]:
		_assert_lines(ending[key], "ending/%s" % key)
	assert_false(str(ending["choices"]["go_home"]).is_empty())
	assert_false(str(ending["choices"]["keep_helping"]).is_empty())
