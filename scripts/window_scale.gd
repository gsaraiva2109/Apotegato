class_name WindowScale
extends RefCounted
## Conta de quanto ampliar a imagem do jogo (feita em resolução fixa, 960 x 544)
## para caber numa área da tela: a janela, o monitor ou a tela cheia. Não
## depende do monitor de ninguém, então os testes usam tamanhos fixos.
##
## No modo pixel perfeito a escala é sempre inteira (cada pixel da arte vira um
## quadrado de 2 x 2, 3 x 3...), o que evita pixels de larguras diferentes. No
## modo preencher a escala é a maior que cabe, mesmo quebrada. Em telas menores
## que a resolução do jogo a escala inteira cortaria a imagem, então nesse caso
## os dois modos reduzem a imagem até ela caber.

## Folga somada antes de arredondar o tamanho da janela para baixo.
const ROUNDING_SLACK := 0.001


## Maior escala que cabe em `area` sem cortar a imagem de tamanho `base`.
static func fit_scale(area: Vector2i, base: Vector2i) -> float:
	if base.x <= 0 or base.y <= 0 or area.x <= 0 or area.y <= 0:
		return 1.0
	return minf(float(area.x) / base.x, float(area.y) / base.y)


## Se a escala inteira vale para essa área: só no modo pixel perfeito e só
## quando cabe pelo menos 1x (abaixo disso ela cortaria a imagem).
static func uses_integer(area: Vector2i, base: Vector2i, pixel_perfect: bool) -> bool:
	return pixel_perfect and fit_scale(area, base) >= 1.0


## Escala que o jogo usa numa área, no modo pedido.
static func content_scale(area: Vector2i, base: Vector2i, pixel_perfect: bool) -> float:
	var fit := fit_scale(area, base)
	if uses_integer(area, base, pixel_perfect):
		return floorf(fit)
	return fit


## Tamanho da janela (sem a barra de título) que mostra o jogo inteiro na maior
## escala que cabe em `area`, sem sobrar borda preta dentro da janela.
static func window_size(area: Vector2i, base: Vector2i, pixel_perfect: bool) -> Vector2i:
	var scale := content_scale(area, base, pixel_perfect)
	# A folga evita perder 1 pixel por erro de arredondamento (1079,9999 vira 1080).
	var size := Vector2i((Vector2(base) * scale + Vector2(ROUNDING_SLACK, ROUNDING_SLACK)).floor())
	return size.clamp(Vector2i.ONE, area.max(Vector2i.ONE))


## Posição que centraliza uma janela de tamanho `size` (com a barra de título)
## dentro de `area` (a parte livre do monitor).
static func centered_position(area: Rect2i, size: Vector2i) -> Vector2i:
	return area.position + ((area.size - size) / 2).max(Vector2i.ZERO)
