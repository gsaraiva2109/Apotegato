extends GutTest
## Confere a tela Fontes: abre na primeira condição, tem um botão por condição,
## troca o conteúdo ao escolher outra, mostra nomes do jogo e links, e fecha com
## Voltar ou Esc.

const SourcesScene := preload("res://scenes/ui/sources_menu.tscn")

const TEST_SETTINGS := "user://test_sources_menu.cfg"

var _menu: SourcesMenu
var _order: Array[String] = []
var _old_settings_path: String


func before_each() -> void:
	_old_settings_path = AudioSettings.settings_path
	AudioSettings.settings_path = TEST_SETTINGS
	AudioSettings.set_large_text(false)
	_menu = autofree(SourcesScene.instantiate())
	add_child(_menu)
	_order = SourcesData.get_condition_order(SourcesData.load_data())


func after_each() -> void:
	AudioSettings.set_large_text(false)
	AudioSettings.settings_path = _old_settings_path
	AudioSettings.load_settings()
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _list() -> VBoxContainer:
	return _menu.get_node("%ConditionList")


func _content() -> RichTextLabel:
	return _menu.get_node("%Content")


func test_starts_closed() -> void:
	assert_false(_menu.is_open())


func test_has_one_button_per_condition() -> void:
	assert_eq(_list().get_child_count(), _order.size())
	for button: Button in _list().get_children():
		assert_ne(button.focus_mode, Control.FOCUS_NONE)
		assert_eq(button.mouse_filter, Control.MOUSE_FILTER_STOP)


func test_opens_on_the_first_condition_with_focus() -> void:
	_menu.open()
	assert_true(_menu.is_open())
	assert_eq(_menu.current_condition(), _order[0])
	var first: Button = _list().get_child(0)
	assert_true(first.has_focus())
	assert_true(first.button_pressed)


func test_choosing_a_condition_shows_its_ingredients() -> void:
	_menu.open()
	(_list().get_node("queimaduras") as Button).pressed.emit()
	assert_eq(_menu.current_condition(), "queimaduras")
	var text := _content().get_parsed_text()
	assert_string_contains(text, "Queimaduras")
	assert_string_contains(text, "Pele de tilápia")
	assert_string_contains(text, "Resina de copaíba")
	assert_string_contains(text, "Referências bibliográficas")


func test_references_have_links() -> void:
	var data := SourcesData.load_data()
	var text := SourcesMenu.build_text(SourcesData.get_condition(data, "diarreia"))
	assert_string_contains(text, "[url=https://pubmed.ncbi.nlm.nih.gov/1496708/]")


func test_brackets_in_the_text_are_not_bbcode() -> void:
	var condition := {
		"name": "Teste",
		"ingredients": [{"id": "mel", "summary": "Texto com [b]colchetes[/b]", "references": []}],
	}
	_content().text = SourcesMenu.build_text(condition)
	assert_string_contains(_content().get_parsed_text(), "[b]colchetes[/b]")


func test_back_button_closes() -> void:
	_menu.open()
	watch_signals(_menu)
	_menu.get_node("%BackButton").pressed.emit()
	assert_false(_menu.is_open())
	assert_signal_emitted(_menu, "closed")


func test_escape_closes() -> void:
	_menu.open()
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_false(_menu.is_open())


func test_titles_grow_with_large_text() -> void:
	var condition := SourcesData.get_condition(SourcesData.load_data(), "queimaduras")
	var normal := SourcesMenu.build_text(condition)
	assert_string_contains(normal, "[font_size=%d]" % SourcesMenu.HEADING_SIZE)
	AudioSettings.set_large_text(true)
	var large := SourcesMenu.build_text(condition)
	for base in [SourcesMenu.HEADING_SIZE, SourcesMenu.INGREDIENT_SIZE, SourcesMenu.SECTION_SIZE]:
		assert_string_contains(large, "[font_size=%d]" % TextSize.scaled(base))
	assert_ne(TextSize.scaled(SourcesMenu.HEADING_SIZE), SourcesMenu.HEADING_SIZE)


func test_open_screen_redraws_when_large_text_changes() -> void:
	_menu.open()
	AudioSettings.set_large_text(true)
	var big := "[font_size=%d]" % TextSize.scaled(SourcesMenu.HEADING_SIZE)
	assert_string_contains(_content().text, big)


func test_only_web_links_open() -> void:
	assert_true(SourcesMenu.is_web_link("https://www.scielo.br/"))
	assert_true(SourcesMenu.is_web_link("http://exemplo.com"))
	for url in ["file:///C:/Windows/System32", "javascript:alert(1)", "res://data/fontes.json", ""]:
		assert_false(SourcesMenu.is_web_link(url), url)
