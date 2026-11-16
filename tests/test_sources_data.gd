extends GutTest
## Valida o data/fontes.json, lido pela tela Fontes: todas as condições na ordem
## do diário, todo par condição–ingrediente do data/ingredientes.csv com as suas
## referências, e nenhum texto ou link vazio.

const DIARY_PATH := "res://data/diario.json"

var _data := {}


func before_all() -> void:
	_data = SourcesData.load_data()


func test_file_loads() -> void:
	assert_false(_data.is_empty(), "Não leu %s" % SourcesData.PATH)


func test_conditions_follow_the_diary_order() -> void:
	var diary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIARY_PATH))
	assert_eq(SourcesData.get_condition_order(_data), Array(diary["condition_order"]))


func test_every_condition_has_a_name_and_ingredients() -> void:
	for condition_id in SourcesData.get_condition_order(_data):
		var condition := SourcesData.get_condition(_data, condition_id)
		assert_false(str(condition.get("name", "")).is_empty(), "%s sem nome" % condition_id)
		assert_gt(condition.get("ingredients", []).size(), 0, "%s sem ingredientes" % condition_id)


func test_every_ingredient_of_the_csv_has_its_sources() -> void:
	for ingredient in IngredientData.get_all_ingredients():
		for condition_id in ingredient.conditions:
			var ids := _ingredient_ids(condition_id)
			assert_has(ids, ingredient.id, "%s sem fontes em %s" % [ingredient.id, condition_id])


func test_only_ingredients_of_the_condition_appear() -> void:
	for condition_id in SourcesData.get_condition_order(_data):
		var expected := []
		for ingredient in IngredientData.get_ingredients_for(condition_id):
			expected.append(ingredient.id)
		for id in _ingredient_ids(condition_id):
			assert_has(expected, id, "%s não é ingrediente de %s" % [id, condition_id])


func test_texts_and_links_are_filled() -> void:
	for condition_id in SourcesData.get_condition_order(_data):
		for ingredient: Dictionary in SourcesData.get_condition(_data, condition_id)["ingredients"]:
			var where := "%s/%s" % [condition_id, ingredient["id"]]
			assert_false(str(ingredient.get("summary", "")).is_empty(), "%s sem resumo" % where)
			var references: Array = ingredient.get("references", [])
			assert_gt(references.size(), 0, "%s sem referências" % where)
			for reference: Dictionary in references:
				assert_false(
					str(reference.get("text", "")).is_empty(), "%s: referência vazia" % where
				)
				assert_string_starts_with(str(reference.get("url", "")), "http", where)


func test_missing_file_gives_empty_data() -> void:
	var data := SourcesData.load_data("res://data/nao_existe.json")
	assert_push_error("Não foi possível abrir")
	assert_true(data.is_empty())


func _ingredient_ids(condition_id: String) -> Array:
	var ids := []
	for ingredient: Dictionary in SourcesData.get_condition(_data, condition_id).get(
		"ingredients", []
	):
		ids.append(ingredient["id"])
	return ids
