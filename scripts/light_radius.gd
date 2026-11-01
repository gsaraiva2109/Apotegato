class_name LightRadius
extends RefCounted
## Fórmula do círculo de luz em volta do gato:
##
##     luz = min(0,6 + 0,12 * n; 1,8)
##
## em que n é o número de criaturas derrotadas no andar. O valor é a escala do
## círculo de luz (`PointLight2D.texture_scale`). Começa em 0,6 e volta a esse
## valor a cada andar novo.

## Luz com nenhuma criatura derrotada.
const BASE := 0.6
## Quanto cada criatura derrotada soma à luz.
const PER_DEFEATED := 0.12
## Teto da luz.
const MAX := 1.8


## Luz para `defeated` criaturas derrotadas no andar. Número negativo conta como
## zero.
static func for_defeated(defeated: int) -> float:
	return minf(BASE + PER_DEFEATED * maxi(defeated, 0), MAX)
