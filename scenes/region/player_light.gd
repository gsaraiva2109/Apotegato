class_name PlayerLight
extends PointLight2D
## O círculo de luz que acompanha o Mingau (fica como filho dele). O tamanho vem
## de `LightRadius` e cresce a cada criatura derrotada no andar; `reset()` volta
## ao tamanho inicial na troca de andar.

## Criaturas derrotadas no andar atual.
var defeated: int = 0


func _ready() -> void:
	reset()


## Conta mais uma criatura derrotada e aumenta a luz.
func add_defeat() -> void:
	defeated += 1
	_update_scale()


## Zera a contagem e volta a luz ao tamanho inicial (novo andar).
func reset() -> void:
	defeated = 0
	_update_scale()


func _update_scale() -> void:
	texture_scale = LightRadius.for_defeated(defeated)
