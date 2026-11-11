extends GutTest
## Confere a conta da escala da janela em monitores de vários tamanhos, de
## netbook a 8K, ultrawide e na vertical. Os tamanhos são fixos: nenhum teste
## depende do monitor de quem roda.

const BASE := Vector2i(960, 544)
## Área livre da tela, escala no modo pixel perfeito e janela no modo preencher.
const SCREENS := [
	[Vector2i(1024, 600), 1, Vector2i(1024, 580)],
	[Vector2i(1280, 720), 1, Vector2i(1270, 720)],
	[Vector2i(1366, 768), 1, Vector2i(1355, 768)],
	[Vector2i(1920, 1080), 1, Vector2i(1905, 1080)],
	[Vector2i(2560, 1440), 2, Vector2i(2541, 1440)],
	[Vector2i(2560, 1600), 2, Vector2i(2560, 1450)],
	[Vector2i(3440, 1440), 2, Vector2i(2541, 1440)],
	[Vector2i(5120, 1440), 2, Vector2i(2541, 1440)],
	[Vector2i(3840, 2160), 3, Vector2i(3811, 2160)],
	[Vector2i(7680, 4320), 7, Vector2i(7623, 4320)],
	[Vector2i(1080, 1920), 1, Vector2i(1080, 612)],
]


func test_pixel_perfect_uses_the_largest_whole_scale() -> void:
	for screen in SCREENS:
		var area: Vector2i = screen[0]
		var scale: int = screen[1]
		assert_eq(WindowScale.content_scale(area, BASE, true), float(scale), "Escala em %s" % area)
		assert_eq(WindowScale.window_size(area, BASE, true), BASE * scale, "Janela em %s" % area)


func test_fill_touches_one_side_of_the_screen() -> void:
	for screen in SCREENS:
		var area: Vector2i = screen[0]
		var size := WindowScale.window_size(area, BASE, false)
		assert_eq(size, screen[2], "Janela em %s" % area)
		assert_true(size.x <= area.x and size.y <= area.y, "Cabe em %s" % area)
		assert_true(size.x == area.x or size.y == area.y, "Encosta na borda em %s" % area)


func test_fill_is_never_smaller_than_pixel_perfect() -> void:
	for screen in SCREENS:
		var area: Vector2i = screen[0]
		assert_true(
			(
				WindowScale.content_scale(area, BASE, false)
				>= WindowScale.content_scale(area, BASE, true)
			)
		)


func test_fill_keeps_the_aspect_ratio() -> void:
	for screen in SCREENS:
		var size := WindowScale.window_size(screen[0], BASE, false)
		var ratio := float(size.x) / size.y
		assert_almost_eq(ratio, float(BASE.x) / BASE.y, 0.01, "Proporção em %s" % screen[0])


func test_small_screen_shrinks_instead_of_cropping() -> void:
	var area := Vector2i(1024, 520)
	assert_false(WindowScale.uses_integer(area, BASE, true))
	assert_almost_eq(WindowScale.content_scale(area, BASE, true), 520.0 / 544.0, 0.001)
	var size := WindowScale.window_size(area, BASE, true)
	assert_true(size.x <= area.x and size.y <= area.y)


func test_integer_only_in_pixel_perfect() -> void:
	assert_true(WindowScale.uses_integer(Vector2i(3440, 1440), BASE, true))
	assert_false(WindowScale.uses_integer(Vector2i(3440, 1440), BASE, false))


func test_exact_multiple_has_no_border() -> void:
	assert_eq(WindowScale.window_size(Vector2i(1920, 1088), BASE, true), Vector2i(1920, 1088))
	assert_eq(WindowScale.window_size(Vector2i(1920, 1088), BASE, false), Vector2i(1920, 1088))


func test_invalid_area_falls_back_to_one() -> void:
	assert_eq(WindowScale.fit_scale(Vector2i.ZERO, BASE), 1.0)


func test_centered_position() -> void:
	var area := Rect2i(0, 0, 3440, 1400)
	assert_eq(WindowScale.centered_position(area, Vector2i(1920, 1118)), Vector2i(760, 141))


func test_centered_position_on_second_monitor() -> void:
	var area := Rect2i(1920, 0, 1920, 1040)
	assert_eq(WindowScale.centered_position(area, Vector2i(960, 574)), Vector2i(2400, 233))


func test_window_larger_than_area_stays_at_the_corner() -> void:
	var area := Rect2i(100, 50, 800, 500)
	assert_eq(WindowScale.centered_position(area, Vector2i(990, 574)), Vector2i(100, 50))
