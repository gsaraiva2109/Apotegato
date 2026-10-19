extends GutTest
## Testa as consultas do autoload IngredientData contra o data/ingredientes.csv
## e as Tabelas 1 e 2 do GDD.

const IngredientDataScript := preload("res://autoload/ingredient_data.gd")

## Tabela 2: ingredientes por região e paridade do andar.
const TABLE_2 := {
	"amazonia": {"impar": ["buriti", "camu_camu"], "par": ["resina_copaiba", "unha_de_gato"]},
	"caatinga": {"impar": ["castanha_caju", "alecrim_pimenta"], "par": ["acerola", "licuri"]},
	"campos_rios":
	{
		"impar": ["pele_tilapia", "banana_da_terra"],
		"par": ["figado_bovino", "erva_cidreira", "semente_chia"],
	},
	"cerrado": {"impar": ["pequi", "flor_assa_peixe"], "par": ["mulungu", "arnica_brasileira"]},
	"litoral": {"impar": ["agua_coco", "sardinha"], "par": ["mel", "aroeira_praia"]},
	"mata_atlantica":
	{
		"impar": ["flor_maracuja", "erva_baleeira", "espinheira_santa"],
		"par": ["folha_goiabeira", "folha_guaco"],
	},
}

## Tabela 1: requisitos de cada condição. Cada grupo interno é "basta um".
const TABLE_1 := {
	"queimaduras": [["resina_copaiba"], ["pele_tilapia"], ["mel"]],
	"diarreia": [["banana_da_terra"], ["agua_coco"], ["folha_goiabeira"]],
	"anemia_ferropriva": [["castanha_caju"], ["figado_bovino"], ["camu_camu", "acerola"]],
	"insonia": [["erva_cidreira"], ["mulungu"], ["flor_maracuja"]],
	"xeroftalmia": [["buriti"], ["licuri"], ["figado_bovino"], ["pequi"]],
	"escorbuto": [["camu_camu"], ["acerola"], ["aroeira_praia"]],
	"resfriado": [["alecrim_pimenta"], ["flor_assa_peixe"], ["mel"], ["folha_guaco"]],
	"dor_muscular": [["unha_de_gato"], ["arnica_brasileira"], ["erva_baleeira"]],
	"gastrite": [["erva_cidreira"], ["aroeira_praia"], ["espinheira_santa"]],
	"ossos_fracos": [["castanha_caju"], ["semente_chia"], ["sardinha"]],
}

var _data: Node


func before_each() -> void:
	_data = autofree(IngredientDataScript.new())
	assert_true(_data.load_csv(IngredientDataScript.CSV_PATH), "CSV não carregou")


func _ids(ingredients: Array[Ingredient]) -> Array:
	return ingredients.map(func(ingredient: Ingredient) -> String: return ingredient.id)


func _sorted(values: Array) -> Array:
	var copy := values.duplicate()
	copy.sort()
	return copy


func _requirements_as_arrays(condition: String) -> Array:
	var result := []
	for group in _data.get_requirements(condition):
		result.append(_sorted(Array(group)))
	return _sorted(result)


func test_autoload_is_registered_and_loaded() -> void:
	var autoload := get_tree().root.get_node_or_null("IngredientData")
	assert_not_null(autoload, "Autoload IngredientData não registrado")
	if autoload != null:
		assert_eq(autoload.get_all_ingredients().size(), 26)


func test_get_ingredient_by_id() -> void:
	var camu_camu: Ingredient = _data.get_ingredient("camu_camu")
	assert_not_null(camu_camu)
	assert_eq(camu_camu.display_name, "Camu-camu")
	assert_eq(camu_camu.region, "amazonia")
	assert_eq(camu_camu.parity, "impar")
	assert_eq(Array(camu_camu.conditions), ["escorbuto", "anemia_ferropriva"])


func test_unknown_ingredient_is_null() -> void:
	assert_null(_data.get_ingredient("nao_existe"))
	assert_false(_data.has_ingredient("nao_existe"))


func test_ingredients_by_region_and_parity_match_table_2() -> void:
	for region in TABLE_2:
		for parity in TABLE_2[region]:
			var ids := _ids(_data.get_ingredients_in(region, parity))
			assert_eq(_sorted(ids), _sorted(TABLE_2[region][parity]), "%s/%s" % [region, parity])


func test_every_ingredient_is_in_table_2() -> void:
	var total := 0
	for region in TABLE_2:
		for parity in TABLE_2[region]:
			total += TABLE_2[region][parity].size()
	assert_eq(_data.get_all_ingredients().size(), total)


func test_unknown_region_has_no_ingredients() -> void:
	assert_eq(_data.get_ingredients_in("pantanal", "par").size(), 0)


func test_conditions_match_table_1() -> void:
	assert_eq(_sorted(Array(_data.get_conditions())), _sorted(TABLE_1.keys()))
	for condition in TABLE_1:
		var expected := []
		for group in TABLE_1[condition]:
			expected.append(_sorted(group))
		assert_eq(_requirements_as_arrays(condition), _sorted(expected), condition)


func test_ingredients_for_condition_include_alternatives() -> void:
	var ids := _ids(_data.get_ingredients_for("anemia_ferropriva"))
	assert_eq(_sorted(ids), ["acerola", "camu_camu", "castanha_caju", "figado_bovino"])


func test_unknown_condition_has_no_requirements() -> void:
	assert_eq(_data.get_requirements("nao_existe").size(), 0)
	assert_eq(_data.get_ingredients_for("nao_existe").size(), 0)
	assert_false(_data.is_condition_satisfied("nao_existe", ["mel"]))


func test_anemia_accepts_camu_camu_or_acerola() -> void:
	var base := ["figado_bovino", "castanha_caju"]
	assert_true(_data.is_condition_satisfied("anemia_ferropriva", base + ["camu_camu"]))
	assert_true(_data.is_condition_satisfied("anemia_ferropriva", base + ["acerola"]))
	assert_true(_data.is_condition_satisfied("anemia_ferropriva", base + ["camu_camu", "acerola"]))
	assert_false(_data.is_condition_satisfied("anemia_ferropriva", base))
	assert_false(
		_data.is_condition_satisfied("anemia_ferropriva", ["camu_camu", "acerola", "castanha_caju"])
	)


func test_scurvy_needs_both_camu_camu_and_acerola() -> void:
	# Fora da anemia, camu-camu e acerola não são alternativas.
	assert_false(_data.is_condition_satisfied("escorbuto", ["camu_camu", "aroeira_praia"]))
	assert_true(
		_data.is_condition_satisfied("escorbuto", ["camu_camu", "acerola", "aroeira_praia"])
	)


func test_conditions_with_four_items_need_all_four() -> void:
	var xerophthalmia := ["buriti", "pequi", "figado_bovino", "licuri"]
	assert_true(_data.is_condition_satisfied("xeroftalmia", xerophthalmia))
	assert_false(_data.is_condition_satisfied("xeroftalmia", xerophthalmia.slice(0, 3)))
	var cold := ["folha_guaco", "mel", "flor_assa_peixe", "alecrim_pimenta"]
	assert_true(_data.is_condition_satisfied("resfriado", cold))
	assert_false(_data.is_condition_satisfied("resfriado", cold.slice(1)))


func test_extra_ingredients_do_not_break_delivery() -> void:
	var delivered := ["sardinha", "castanha_caju", "semente_chia", "mel", "buriti"]
	assert_true(_data.is_condition_satisfied("ossos_fracos", delivered))


func test_missing_file_returns_false() -> void:
	assert_false(_data.load_csv("res://data/nao_existe.csv"))
	assert_eq(_data.get_all_ingredients().size(), 0)
