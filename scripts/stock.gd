class_name Stock
extends RefCounted
## O estoque da apotecária: guarda as sobras das entregas por id de ingrediente,
## sem limite de espaços. O que está aqui conta na hora de completar uma entrega.
##
## É só dado, sem cena.

## Emitido sempre que o conteúdo muda.
signal changed

## id do ingrediente -> quantidade.
var _items: Dictionary = {}


## Guarda `amount` unidades do ingrediente.
func store(id: String, amount: int = 1) -> bool:
	if id.is_empty() or amount <= 0:
		return false
	_items[id] = count(id) + amount
	changed.emit()
	return true


## Retira `amount` unidades. Se não houver essa quantidade, não retira nada e
## devolve false.
func take(id: String, amount: int = 1) -> bool:
	if amount <= 0 or count(id) < amount:
		return false
	var left := count(id) - amount
	if left == 0:
		_items.erase(id)
	else:
		_items[id] = left
	changed.emit()
	return true


func count(id: String) -> int:
	return _items.get(id, 0)


func is_empty() -> bool:
	return _items.is_empty()


## Total de unidades guardadas.
func total_count() -> int:
	var total := 0
	for amount: int in _items.values():
		total += amount
	return total


## Ids guardados, na ordem em que entraram no estoque.
func ids() -> Array[String]:
	var result: Array[String] = []
	result.assign(_items.keys())
	return result


## Ids disponíveis para uma entrega: o que está na mochila mais o que está no
## estoque, sem repetir. É o que se passa para
## `IngredientData.is_condition_satisfied`.
func ids_for_delivery(backpack: Backpack) -> Array[String]:
	var result := backpack.ids()
	for id in ids():
		if id not in result:
			result.append(id)
	return result


## Esvazia o estoque.
func clear() -> void:
	if _items.is_empty():
		return
	_items.clear()
	changed.emit()
