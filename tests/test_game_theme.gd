extends GutTest
## Confere o tema único da interface: painel e botões em 9-slice, com a arte
## provisória ou a do UI Medieval Mega (mesmos nomes e tamanhos).

const THEME := preload("res://scenes/ui/game_theme.tres")
const BUTTON_STATES := ["normal", "hover", "pressed", "disabled"]


func test_panel_uses_nine_slice_texture() -> void:
	var style := THEME.get_stylebox("panel", "PanelContainer")
	assert_true(style is StyleBoxTexture)
	assert_eq((style as StyleBoxTexture).texture_margin_left, 9.0)


func test_button_states_use_nine_slice_texture() -> void:
	for state: String in BUTTON_STATES:
		var style := THEME.get_stylebox(state, "Button")
		assert_true(style is StyleBoxTexture, "Botão sem textura no estado %s" % state)


func test_button_art_has_the_expected_size() -> void:
	for state in ["button_normal", "button_pressed", "button_disabled"]:
		var texture: Texture2D = load("res://assets/art/ui/%s.png" % state)
		assert_eq(texture.get_size(), Vector2(48, 16), state)


func test_hearts_have_the_expected_size() -> void:
	for heart in ["heart_full", "heart_empty"]:
		var texture: Texture2D = load("res://assets/art/ui/%s.png" % heart)
		assert_eq(texture.get_size(), Vector2(18, 15), heart)


func test_plank_variation_uses_nine_slice_texture() -> void:
	assert_true(THEME.get_stylebox("panel", "PlankPanel") is StyleBoxTexture)
	assert_true(THEME.get_color("font_color", "PlankLabel").v < 0.2, "Texto escuro sobre a tábua")


func test_parchment_variation_uses_nine_slice_texture() -> void:
	var style := THEME.get_stylebox("panel", "ParchmentPanel")
	assert_true(style is StyleBoxTexture)
	assert_eq((style as StyleBoxTexture).texture_margin_top, 26.0)
	for label_type in ["ParchmentLabel", "ParchmentTitle", "ParchmentSubtitle"]:
		assert_true(THEME.get_color("font_color", label_type).v < 0.5, "Texto escuro no pergaminho")


func test_journal_uses_the_game_theme_and_parchment() -> void:
	var journal: CanvasLayer = autofree(load("res://scenes/ui/journal.tscn").instantiate())
	add_child(journal)
	assert_eq(journal.get_node("Root").theme, THEME)
	assert_eq(journal.get_node("Root/Center/Panel").theme_type_variation, &"ParchmentPanel")


func test_bars_and_slider_use_the_pack_style() -> void:
	assert_true(THEME.get_stylebox("fill", "ProgressBar") is StyleBoxTexture)
	assert_true(THEME.get_stylebox("slider", "HSlider") is StyleBoxTexture)
	assert_not_null(THEME.get_icon("grabber", "HSlider"))


func test_extra_art_has_the_expected_size() -> void:
	var sizes := {
		"plank": Vector2(119, 51),
		"bar_fill": Vector2(48, 16),
		"slider_grabber": Vector2(10, 10),
		"backpack_icon": Vector2(64, 79),
		"cursor": Vector2(11, 14),
		"parchment": Vector2(150, 89),
	}
	for art: String in sizes:
		var texture: Texture2D = load("res://assets/art/ui/%s.png" % art)
		assert_eq(texture.get_size(), sizes[art], art)
