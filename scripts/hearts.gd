class_name Hearts
extends RefCounted
## A vida do Mingau: 7 corações, contados em meios corações (14 meios). Cada golpe
## tira o dano da criatura, que pode ser meio coração ou mais. Ao zerar, ele
## desmaia. Recuperar vida nunca passa do máximo.
##
## Todas as quantidades daqui são em meios corações. É só dado, sem cena: o HUD
## e o gato leem daqui.

## Emitido sempre que a vida muda, com os valores em meios corações.
signal changed(current: int, maximum: int)

## Como um ícone de coração aparece: vazio, pela metade ou cheio.
enum Fill { EMPTY, HALF, FULL }

## Quantos corações cabem no HUD.
const MAX_HEARTS := 7
## Quantos meios corações formam um coração.
const HALVES_PER_HEART := 2
## Vida máxima, em meios corações.
const MAX := MAX_HEARTS * HALVES_PER_HEART

var current: int = MAX


## Como o coração de índice `index` (0 é o primeiro da esquerda) aparece quando a
## vida é `halves` meios corações.
static func fill_of(index: int, halves: int) -> Fill:
	var left := halves - index * HALVES_PER_HEART
	if left >= HALVES_PER_HEART:
		return Fill.FULL
	if left == 1:
		return Fill.HALF
	return Fill.EMPTY


## Tira `amount` meios corações (não passa de zero).
func hurt(amount: int = 1) -> void:
	if amount <= 0 or current == 0:
		return
	current = maxi(current - amount, 0)
	changed.emit(current, MAX)


## Recupera até `amount` meios corações, sem passar do máximo. Devolve quantos
## recuperou de fato (0 se já estava cheio).
func heal(amount: int = 1) -> int:
	var recovered := mini(amount, MAX - current)
	if recovered <= 0:
		return 0
	current += recovered
	changed.emit(current, MAX)
	return recovered


## Volta à vida máxima.
func restore() -> void:
	heal(MAX - current)


## Quantos meios corações faltam para a vida máxima.
func missing() -> int:
	return MAX - current


func is_empty() -> bool:
	return current <= 0


func is_full() -> bool:
	return current >= MAX
