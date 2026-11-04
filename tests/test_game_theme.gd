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
