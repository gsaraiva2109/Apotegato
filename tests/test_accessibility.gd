extends GutTest
## Confere o mínimo de acessibilidade da interface: nenhum texto abaixo de
## `MIN_FONT_SIZE` (tema e overrides nas cenas) e contraste mínimo das cores de
## texto do tema sobre o fundo em que cada uma aparece.

const THEME := preload("res://scenes/ui/game_theme.tres")
## Piso de fonte, em pixels, antes do "Texto grande".
const MIN_FONT_SIZE := 16
## Contraste mínimo (WCAG AA para texto normal).
const MIN_CONTRAST := 4.5

## Cor média de cada fundo de texto: média dos pixels opacos da textura (nas tábuas,
## sem a borda), já com o `modulate_color` do estilo quando há. Se trocar a arte,
## recalcule aqui.
const PANEL_BG := Color8(86, 47, 33)
const BUTTON_BG := Color8(113, 80, 56)
const BUTTON_HOVER_BG := Color8(141, 100, 70)
const BUTTON_PRESSED_BG := Color8(106, 63, 63)
const BUTTON_DISABLED_BG := Color8(92, 74, 63)
const PLANK_BG := Color8(192, 98, 29)
const PARCHMENT_BG := Color8(187, 165, 126)
const SCROLL_BUTTON_BGS: Array[Color] = [
	Color8(217, 188, 150),
	Color8(224, 199, 144),
	Color8(203, 158, 103),
]


## Contraste WCAG entre duas cores (de 1 a 21).
func _contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


func _luminance(c: Color) -> float:
	return 0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b)


func _linear(v: float) -> float:
	return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)


func _tscn_files(dir_path: String) -> Array[String]:
	var files: Array[String] = []
	for file in DirAccess.get_files_at(dir_path):
		if file.ends_with(".tscn"):
			files.append(dir_path.path_join(file))
	for sub in DirAccess.get_directories_at(dir_path):
		files.append_array(_tscn_files(dir_path.path_join(sub)))
	return files


func test_theme_font_sizes_respect_the_floor() -> void:
	assert_gte(THEME.default_font_size, MIN_FONT_SIZE, "default_font_size")
	for type_name in THEME.get_font_size_type_list():
		for item in THEME.get_font_size_list(type_name):
			var size := THEME.get_font_size(item, type_name)
			assert_gte(size, MIN_FONT_SIZE, "%s/%s" % [type_name, item])


func test_scene_font_size_overrides_respect_the_floor() -> void:
	var regex := RegEx.create_from_string("theme_override_font_sizes/\\w+ = (\\d+)")
	var checked := 0
	for path in _tscn_files("res://scenes"):
		var text := FileAccess.get_file_as_string(path)
		for found in regex.search_all(text):
			checked += 1
			assert_gte(
				int(found.get_string(1)), MIN_FONT_SIZE, "%s: %s" % [path, found.get_string()]
			)
	assert_gt(checked, 0, "O teste precisa encontrar overrides para valer")


func test_label_and_button_text_contrast() -> void:
	var label := THEME.get_color("font_color", "Label")
	assert_gte(_contrast(label, PANEL_BG), MIN_CONTRAST, "Label sobre o painel")
	var muted := THEME.get_color("font_color", "MutedLabel")
	assert_gte(_contrast(muted, PANEL_BG), MIN_CONTRAST, "MutedLabel (Vazio, dicas) sobre o painel")
	var cases := {
		"font_color": BUTTON_BG,
		"font_hover_color": BUTTON_HOVER_BG,
		"font_focus_color": BUTTON_BG,
		"font_pressed_color": BUTTON_PRESSED_BG,
		"font_hover_pressed_color": BUTTON_PRESSED_BG,
		"font_disabled_color": BUTTON_DISABLED_BG,
	}
	for item: String in cases:
		for type_name in ["Button", "CheckButton"]:
			var color := THEME.get_color(item, type_name)
			assert_gte(_contrast(color, cases[item]), MIN_CONTRAST, "%s/%s" % [type_name, item])


func test_plank_and_parchment_text_contrast() -> void:
	assert_gte(
		_contrast(THEME.get_color("font_color", "PlankLabel"), PLANK_BG),
		MIN_CONTRAST,
		"PlankLabel sobre a tábua"
	)
	var parchment_colors := {
		"ParchmentLabel/font_color": THEME.get_color("font_color", "ParchmentLabel"),
		"ParchmentTitle/font_color": THEME.get_color("font_color", "ParchmentTitle"),
		"ParchmentSubtitle/font_color": THEME.get_color("font_color", "ParchmentSubtitle"),
		"ParchmentRichText/default_color": THEME.get_color("default_color", "ParchmentRichText"),
	}
	for key: String in parchment_colors:
		assert_gte(_contrast(parchment_colors[key], PARCHMENT_BG), MIN_CONTRAST, key)


func test_scroll_button_text_contrast() -> void:
	for item in [
		"font_color",
		"font_focus_color",
		"font_hover_color",
		"font_pressed_color",
		"font_hover_pressed_color"
	]:
		var color := THEME.get_color(item, "ScrollButton")
		for bg in SCROLL_BUTTON_BGS:
			assert_gte(_contrast(color, bg), MIN_CONTRAST, "ScrollButton/%s" % item)
