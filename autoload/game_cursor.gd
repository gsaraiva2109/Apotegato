extends Node
## Troca o cursor do mouse pela seta do UI Medieval Mega (ou pela provisória,
## quando o pacote não foi baixado), ampliada com pixels nítidos. Sem janela
## (testes e CI em modo headless) não faz nada.
##
## Registrado como autoload "GameCursor". Não usa `class_name` de outros
## scripts porque o autoload é lido antes de o Godot registrá-los.

const CURSOR_TEXTURE := preload("res://assets/art/ui/cursor.png")
## Quantas vezes a seta é ampliada (a arte original tem uns 11 x 14 pixels).
const SCALE := 2


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var cursor := ImageTexture.create_from_image(scaled_image(CURSOR_TEXTURE.get_image(), SCALE))
	Input.set_custom_mouse_cursor(cursor, Input.CURSOR_ARROW, Vector2.ZERO)


## Amplia `source` por um fator inteiro, sem suavizar os pixels.
static func scaled_image(source: Image, factor: int) -> Image:
	var result := source.duplicate() as Image
	result.resize(
		source.get_width() * factor, source.get_height() * factor, Image.INTERPOLATE_NEAREST
	)
	return result
