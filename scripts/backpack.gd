class_name Backpack
extends RefCounted
## A mochila do Mingau: 6 espaços fixos, e os itens iguais (mesmo id de
## ingrediente) empilham no mesmo espaço. Com os 6 espaços ocupados por ids
## diferentes, um ingrediente novo é recusado.
##
## É só dado, sem cena: a tela de mochila e o contador da exploração leem daqui.

## Emitido sempre que o conteúdo muda.
signal changed
## Emitido quando um ingrediente é recusado por falta de espaço (o aviso da tela).
signal rejected(id: String)

## Quantidade de espaços da mochila.
const MAX_SLOTS := 6

## id do ingrediente -> quantidade. Cada id ocupa um espaço.
var _items: Dictionary = {}


## Guarda `amount` unidades do ingrediente. Soma ao espaço que já tem esse id; se
## não tiver e os espaços estiverem cheios, recusa (devolve false e emite
## `rejected`) sem guardar nada.
func add(id: String, amount: int = 1) -> bool:
	if id.is_empty() or amount <= 0:
		return false
	if not can_add(id):
		rejected.emit(id)
		return false
	_items[id] = count(id) + amount
	changed.emit()
	return true


## Tira `amount` unidades. Se não houver essa quantidade, não tira nada e
## devolve false. Quando a quantidade chega a zero, o espaço fica livre.
func remove(id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(id) < amount:
		return false
	var left := count(id) - amount
	if left == 0:
		_items.erase(id)
	else:
		_items[id] = left
	changed.emit()
	return true


## Quantas unidades desse ingrediente a mochila tem.
func count(id: String) -> int:
	return _items.get(id, 0)


## Se um ingrediente com esse id cabe: já tem espaço próprio ou sobra um livre.
func can_add(id: String) -> bool:
	return _items.has(id) or used_slots() < MAX_SLOTS


## Espaços ocupados (ids diferentes).
func used_slots() -> int:
	return _items.size()


func free_slots() -> int:
	return MAX_SLOTS - used_slots()


## Os 6 espaços ocupados por ids diferentes.
func is_full() -> bool:
	return used_slots() >= MAX_SLOTS


func is_empty() -> bool:
	return _items.is_empty()


## Total de unidades, somando todos os espaços.
func total_count() -> int:
	var total := 0
	for amount: int in _items.values():
		total += amount
	return total


## Ids guardados, na ordem em que entraram na mochila.
func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_items.keys())
	return result


## Esvazia a mochila.
func clear() -> void:
	if _items.is_empty():
		return
	_items.clear()
	changed.emit()
