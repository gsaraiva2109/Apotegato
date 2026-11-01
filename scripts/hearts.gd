class_name Hearts
extends RefCounted
## Os corações do Mingau: 7 no máximo. Cada contato com uma criatura tira um e,
## ao zerar, ele desmaia. Recuperar coração nunca passa de 7.
##
## É só dado, sem cena: o HUD e o gato leem daqui.

## Emitido sempre que a quantidade muda.
signal changed(current: int, maximum: int)

## Quantidade máxima de corações.
const MAX := 7

var current: int = MAX


## Tira `amount` corações (não passa de zero).
func hurt(amount: int = 1) -> void:
	if amount <= 0 or current == 0:
		return
	current = maxi(current - amount, 0)
	changed.emit(current, MAX)


## Recupera até `amount` corações, sem passar de 7. Devolve quantos recuperou de
## fato (0 se já estava cheio).
func heal(amount: int = 1) -> int:
	var recovered := mini(amount, MAX - current)
	if recovered <= 0:
		return 0
	current += recovered
	changed.emit(current, MAX)
	return recovered


## Volta aos 7 corações.
func restore() -> void:
	heal(MAX - current)


func is_empty() -> bool:
	return current <= 0


func is_full() -> bool:
	return current >= MAX
