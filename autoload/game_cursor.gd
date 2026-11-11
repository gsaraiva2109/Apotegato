extends Node
## Troca o cursor do mouse pela seta do UI Medieval Mega (ou pela provisória,
## quando o pacote não foi baixado), ampliada com pixels nítidos. O cursor do
## sistema não acompanha a escala do jogo, então a seta é refeita sempre que a
## ampliação muda (`DisplaySettings.scale_changed`): no modo pixel perfeito cada
## pixel da seta fica do tamanho de um pixel do jogo. Sem janela (testes e CI em
## modo headless) não faz nada.
##
## Registrado como autoload "GameCursor". Não usa `class_name` de outros
## scripts porque o autoload é lido antes de o Godot registrá-los.

const CURSOR_TEXTURE := preload("res://assets/art/ui/cursor.png")
## Menor ampliação da seta (a arte original tem uns 11 x 14 pixels); abaixo
## disso ela fica pequena demais para ler, mesmo com o jogo em 1x.
const MIN_SCALE := 2
## Maior ampliação da seta. O Godot não aceita cursor maior que 256 x 256.
const MAX_SCALE := 8

## Ampliação da seta em uso (0 enquanto nenhuma foi aplicada).
var _factor := 0


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplaySettings.scale_changed.connect(_apply_scale)
	_apply_scale(DisplaySettings.current_scale)


## Ao fechar o jogo, devolve o cursor padrão: o `Input` guarda a textura e, sem
## isso, o Godot avisa que ela vazou na saída.
func _exit_tree() -> void:
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)


## Ampliação da seta para o jogo ampliado `content_scale` vezes: a mesma escala,
## arredondada e limitada entre MIN_SCALE e MAX_SCALE.
static func factor_for(content_scale: float) -> int:
	return clampi(roundi(content_scale), MIN_SCALE, MAX_SCALE)


## Amplia `source` por um fator inteiro, sem suavizar os pixels.
static func scaled_image(source: Image, factor: int) -> Image:
	var result := source.duplicate() as Image
	result.resize(
		source.get_width() * factor, source.get_height() * factor, Image.INTERPOLATE_NEAREST
	)
	return result


## Refaz a seta na ampliação certa para o jogo ampliado `content_scale` vezes.
func _apply_scale(content_scale: float) -> void:
	var factor := factor_for(content_scale)
	if factor == _factor:
		return
	_factor = factor
	var image := scaled_image(CURSOR_TEXTURE.get_image(), factor)
	Input.set_custom_mouse_cursor(ImageTexture.create_from_image(image), Input.CURSOR_ARROW)
