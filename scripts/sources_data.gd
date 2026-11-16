class_name SourcesData
extends RefCounted
## Lê o data/fontes.json, com as referências científicas de cada ingrediente
## por condição. Quem usa é a tela Fontes do menu inicial.
##
## Formato: `condition_order` (ids na ordem de exibição) e `conditions`, em que
## cada condição tem `name` e `ingredients`. Cada ingrediente tem `id` (igual ao
## do data/ingredientes.csv), `summary`, `limitations` e `references`, uma lista
## de `{"text": ..., "url": ...}`.

const PATH := "res://data/fontes.json"


## Lê o arquivo e devolve o dicionário, ou um dicionário vazio se não der.
static func load_data(path: String = PATH) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_error("%s não é um JSON válido" % path)
		return {}
	return parsed


## Ids das condições, na ordem em que aparecem na tela.
static func get_condition_order(data: Dictionary) -> Array[String]:
	var order: Array[String] = []
	for condition_id: String in data.get("condition_order", []):
		order.append(condition_id)
	return order


## Dados de uma condição (`name` e `ingredients`), ou vazio se não existir.
static func get_condition(data: Dictionary, condition_id: String) -> Dictionary:
	return data.get("conditions", {}).get(condition_id, {})
