extends GutTest
## Confere o sorteio de pacientes: nenhuma condição se repete, só saem condições
## possíveis e a campanha inteira cobre as 10 condições.

var _picker: PatientPicker
var _rng: RandomNumberGenerator


func before_each() -> void:
	_picker = PatientPicker.new()
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345
	GameState.new_game()


func after_all() -> void:
	GameState.new_game()


func _serve_all() -> Array[String]:
	var served: Array[String] = []
	for i in 10:
		var condition := _picker.pick(_rng)
		served.append(condition)
		_picker.mark_attended(condition)
	return served


func test_ten_draws_cover_the_ten_conditions() -> void:
	var served := _serve_all()
	var sorted := served.duplicate()
	sorted.sort()
	var expected := Array(IngredientData.get_conditions())
	expected.sort()
	assert_eq(sorted, expected)
	assert_eq(_picker.attended_count(), 10)


func test_works_with_any_seed() -> void:
	for seed_value in 50:
		_picker.reset()
		_rng.seed = seed_value
		var served := _serve_all()
		var unique := {}
		for condition in served:
			unique[condition] = true
		assert_eq(unique.size(), 10, "seed %d repetiu condição" % seed_value)


func test_first_patient_is_also_drawn() -> void:
	var first := _picker.pick(_rng)
	assert_true(first in IngredientData.get_conditions())


func test_attended_condition_is_never_drawn_again() -> void:
	var first := _picker.pick(_rng)
	_picker.mark_attended(first)
	for i in 50:
		assert_ne(_picker.pick(_rng), first)


func test_pick_does_not_mark_as_attended() -> void:
	_picker.pick(_rng)
	assert_eq(_picker.attended_count(), 0)
	assert_eq(_picker.remaining().size(), 10)


func test_draw_after_the_tenth_is_empty() -> void:
	_serve_all()
	assert_eq(_picker.pick(_rng), "")
	assert_true(_picker.remaining().is_empty())


func test_mark_attended_rejects_unknown_and_repeated() -> void:
	assert_false(_picker.mark_attended("gripe_inventada"))
	assert_true(_picker.mark_attended("diarreia"))
	assert_false(_picker.mark_attended("diarreia"))
	assert_true(_picker.is_attended("diarreia"))
	assert_eq(_picker.attended(), ["diarreia"] as Array[String])


func test_every_drawn_patient_has_all_ingredients_available() -> void:
	for condition in IngredientData.get_conditions():
		assert_true(PatientPicker.is_feasible(condition), condition)
		for group in IngredientData.get_requirements(condition):
			var available := false
			for id in group:
				var ingredient := IngredientData.get_ingredient(id)
				if not (
					IngredientData
					. get_ingredients_in(ingredient.region, ingredient.parity)
					. is_empty()
				):
					available = true
			assert_true(available, "requisito impossível em %s" % condition)


func test_unknown_condition_is_not_feasible() -> void:
	assert_false(PatientPicker.is_feasible("gripe_inventada"))


func test_game_state_holds_picker_and_new_game_resets_it() -> void:
	GameState.patients.mark_attended("insonia")
	assert_eq(GameState.patients.attended_count(), 1)
	GameState.new_game()
	assert_eq(GameState.patients.attended_count(), 0)


func test_campaign_complete_after_ten_attendances() -> void:
	assert_false(_picker.is_campaign_complete())
	_serve_all()
	assert_true(_picker.is_campaign_complete())


func test_continuous_mode_draws_any_condition_without_immediate_repeat() -> void:
	_serve_all()
	var seen := {}
	var previous := "diarreia"
	for i in 200:
		var condition := _picker.pick_continuous(_rng, previous)
		assert_true(condition in IngredientData.get_conditions())
		assert_ne(condition, previous)
		seen[condition] = true
		previous = condition
	assert_eq(seen.size(), 10)
