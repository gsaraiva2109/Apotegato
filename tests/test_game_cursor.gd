extends GutTest
## Confere a ampliação do cursor do mouse.

const GameCursorScript := preload("res://autoload/game_cursor.gd")


func test_scaled_image_multiplies_the_size() -> void:
	var source := Image.create(5, 7, false, Image.FORMAT_RGBA8)
	var scaled: Image = GameCursorScript.scaled_image(source, 3)
	assert_eq(scaled.get_size(), Vector2i(15, 21))
	assert_eq(source.get_size(), Vector2i(5, 7), "A imagem original não muda")
