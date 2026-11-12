extends GutTest
## Testa o carregamento, a construção e a navegação do diário.

const JournalScene := preload("res://scenes/ui/journal.tscn")


func after_each() -> void:
	GameState.flow.reset()
	get_tree().paused = false


func _create_journal() -> Node:
	var journal: Node = JournalScene.instantiate()
	autofree(journal)
	add_child(journal)
	return journal


# =====================================================
# CARREGAMENTO
# =====================================================


func test_loads_journal_data_and_builds_pages() -> void:
	var journal := _create_journal()

	var data: Dictionary = journal.get("_journal_data")
	var pages: Array = journal.get("_pages")

	assert_true(FileAccess.file_exists("res://data/diario.json"))
	assert_false(data.is_empty(), "O JSON deve ser carregado.")
	assert_true(pages.size() > 0, "O diário deve construir páginas.")


# =====================================================
# PÁGINAS DAS REGIÕES
# =====================================================


func test_region_pages_follow_json_order() -> void:
	var journal := _create_journal()

	var data: Dictionary = journal.get("_journal_data")
	var regions: Dictionary = data.get("regions", {})
	var region_order: Array = data.get("region_order", [])

	var expected_ids: Array[String] = []

	for region_id_value: Variant in region_order:
		var region_id := str(region_id_value)

		if regions.has(region_id):
			expected_ids.append(region_id)

	var actual_ids: Array[String] = []

	for page: Dictionary in journal.get("_pages"):
		if page.get("category", "") == "region":
			actual_ids.append(str(page.get("id", "")))

	assert_true(expected_ids.size() > 0)
	assert_eq(actual_ids, expected_ids)


# =====================================================
# PÁGINAS DAS CONDIÇÕES
# =====================================================


func test_condition_pages_follow_json_order() -> void:
	var journal := _create_journal()

	var data: Dictionary = journal.get("_journal_data")
	var conditions: Dictionary = data.get("conditions", {})
	var condition_order: Array = data.get("condition_order", [])

	var expected_ids: Array[String] = []

	for condition_id_value: Variant in condition_order:
		var condition_id := str(condition_id_value)

		if conditions.has(condition_id):
			expected_ids.append(condition_id)

	var actual_ids: Array[String] = []

	for page: Dictionary in journal.get("_pages"):
		if page.get("category", "") == "condition":
			actual_ids.append(str(page.get("id", "")))

	assert_true(expected_ids.size() > 0)
	assert_eq(actual_ids, expected_ids)


# =====================================================
# PÁGINAS DOS INGREDIENTES
# =====================================================


func test_ingredient_pages_match_registered_ingredients() -> void:
	var journal := _create_journal()

	var expected_ids: Array[String] = []

	for ingredient: Ingredient in IngredientData.get_all_ingredients():
		expected_ids.append(ingredient.id)

	var actual_ids: Array[String] = []

	for page: Dictionary in journal.get("_pages"):
		if page.get("category", "") == "item":
			actual_ids.append(str(page.get("id", "")))

	assert_true(expected_ids.size() > 0)
	assert_eq(actual_ids, expected_ids)


# =====================================================
# ESTRUTURA DAS PÁGINAS
# =====================================================


func test_all_pages_have_required_fields() -> void:
	var journal := _create_journal()
	var pages: Array = journal.get("_pages")

	var required_fields := [
		"title",
		"subtitle",
		"content",
		"image",
		"category",
	]

	for page: Dictionary in pages:
		for field: String in required_fields:
			assert_true(page.has(field), "Página sem o campo obrigatório: " + field)


func test_static_page_preserves_source_data() -> void:
	var journal := _create_journal()

	var source := {
		"title": "Teste",
		"subtitle": "Introdução",
		"content": "Conteúdo de teste",
		"image": "",
		"category": "introduction",
	}

	var result: Dictionary = journal.call("_make_static_page", source)

	assert_eq(result, source)


func test_static_page_uses_empty_defaults() -> void:
	var journal := _create_journal()

	var result: Dictionary = journal.call("_make_static_page", {})

	assert_eq(
		result,
		{
			"title": "",
			"subtitle": "",
			"content": "",
			"image": "",
			"category": "",
		}
	)


# =====================================================
# NOMES DAS REGIÕES
# =====================================================


func test_get_region_name_returns_registered_name() -> void:
	var journal := _create_journal()

	assert_eq(journal.call("_get_region_name", "cerrado"), "Cerrado")


func test_unknown_region_name_returns_original_id() -> void:
	var journal := _create_journal()

	assert_eq(journal.call("_get_region_name", "regiao_inexistente"), "regiao_inexistente")


# =====================================================
# NAVEGAÇÃO
# =====================================================


func test_page_navigation_moves_forward_and_backward() -> void:
	var journal := _create_journal()
	var pages: Array = journal.get("_pages")

	assert_true(pages.size() > 1)

	journal.call("_go_to_next_page")
	assert_eq(journal.get("_current_page"), 1)

	journal.call("_go_to_previous_page")
	assert_eq(journal.get("_current_page"), 0)


func test_previous_page_does_not_go_below_first_page() -> void:
	var journal := _create_journal()

	journal.set("_current_page", 0)
	journal.call("_go_to_previous_page")

	assert_eq(journal.get("_current_page"), 0)


func test_next_page_does_not_exceed_last_page() -> void:
	var journal := _create_journal()
	var pages: Array = journal.get("_pages")

	var last_page := pages.size() - 1

	journal.set("_current_page", last_page)
	journal.call("_go_to_next_page")

	assert_eq(journal.get("_current_page"), last_page)


# =====================================================
# ABRIR E FECHAR
# =====================================================


func test_journal_starts_closed() -> void:
	var journal := _create_journal()

	var root: Control = journal.get_node("Root")

	assert_false(root.visible)


func test_open_and_close_journal_restores_pause_state() -> void:
	var journal := _create_journal()
	var root: Control = journal.get_node("Root")

	journal.call("open")

	assert_true(root.visible)
	assert_true(get_tree().paused)

	journal.call("close")

	assert_false(root.visible)
	assert_false(get_tree().paused)


func test_journal_is_a_menu_of_the_state_machine() -> void:
	var journal := _create_journal()

	journal.call("open")
	assert_true(GameState.flow.is_in(GameFlow.State.MENU))

	journal.call("close")
	assert_true(GameState.flow.is_in(GameFlow.State.EXPLORATION))


func test_does_not_open_outside_exploration() -> void:
	var journal := _create_journal()
	var root: Control = journal.get_node("Root")

	GameState.flow.request(GameFlow.State.DIALOGUE)
	journal.call("open")
	assert_false(root.visible, "Não abre por cima de um diálogo")

	GameState.flow.reset()
	GameState.flow.open_menu()
	journal.call("open")
	assert_false(root.visible, "Não abre por cima de outro menu")
