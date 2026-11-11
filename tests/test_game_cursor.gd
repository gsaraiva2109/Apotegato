extends GutTest
## Confere a ampliação do cursor do mouse.

const GameCursorScript := preload("res://autoload/game_cursor.gd")


func test_scaled_image_multiplies_the_size() -> void:
	var source := Image.create(5, 7, false, Image.FORMAT_RGBA8)
	var scaled: Image = GameCursorScript.scaled_image(source, 3)
	assert_eq(scaled.get_size(), Vector2i(15, 21))
	assert_eq(source.get_size(), Vector2i(5, 7), "A imagem original não muda")


func test_cursor_follows_the_game_scale() -> void:
	assert_eq(GameCursorScript.factor_for(3.0), 3)
	assert_eq(GameCursorScript.factor_for(2.65), 3)
	assert_eq(GameCursorScript.factor_for(4.0), 4)


func test_cursor_stays_readable_in_small_windows() -> void:
	assert_eq(GameCursorScript.factor_for(1.0), GameCursorScript.MIN_SCALE)
	assert_eq(GameCursorScript.factor_for(0.9), GameCursorScript.MIN_SCALE)


func test_cursor_never_exceeds_the_godot_limit() -> void:
	var factor: int = GameCursorScript.factor_for(20.0)
	assert_eq(factor, GameCursorScript.MAX_SCALE)
	var image := GameCursorScript.CURSOR_TEXTURE.get_image()
	assert_true(image.get_width() * factor <= 256 and image.get_height() * factor <= 256)
