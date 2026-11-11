extends GutTest
## Confere que o data/diario.json tem o texto de todas as páginas do diário:
## as 10 condições e os 26 ingredientes do CSV.

const JOURNAL_PATH := "res://data/diario.json"

var _data: Dictionary


func before_each() -> void:
	var file := FileAccess.open(JOURNAL_PATH, FileAccess.READ)
	_data = JSON.parse_string(file.get_as_text())


func test_every_condition_has_a_text() -> void:
	var conditions: Dictionary = _data["conditions"]
	var csv_conditions := IngredientData.get_conditions()
	assert_eq(csv_conditions.size(), 10)
	for condition in csv_conditions:
		assert_true(conditions.has(condition), "sem texto para a condição %s" % condition)
		assert_false(
			str(conditions[condition].get("content_before", "")).strip_edges().is_empty(),
			"texto vazio na condição %s" % condition
		)
		assert_false(
			str(conditions[condition].get("title", "")).strip_edges().is_empty(),
			"sem título na condição %s" % condition
		)


func test_every_ingredient_has_a_text() -> void:
	var ingredients: Dictionary = _data["ingredients"]
	var all := IngredientData.get_all_ingredients()
	assert_eq(all.size(), 26)
	for ingredient in all:
		assert_true(ingredients.has(ingredient.id), "sem texto para %s" % ingredient.id)
		assert_false(
			str(ingredients[ingredient.id].get("content_before", "")).strip_edges().is_empty(),
			"texto vazio em %s" % ingredient.id
		)


func test_orders_list_only_known_pages() -> void:
	for id: String in _data["condition_order"]:
		assert_true(_data["conditions"].has(id), "ordem cita condição inexistente %s" % id)
	for id: String in _data["ingredient_order"]:
		assert_true(_data["ingredients"].has(id), "ordem cita ingrediente inexistente %s" % id)
	assert_eq(_data["condition_order"].size(), 10)
	assert_eq(_data["ingredient_order"].size(), 26)
