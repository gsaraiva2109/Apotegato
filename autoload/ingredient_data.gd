extends Node
## Fonte única dos dados de ingredientes e condições. Lê o
## data/ingredientes.csv uma vez, ao iniciar o jogo, e responde às consultas do
## diário, do gerador de itens e da entrega.
##
## Registrado como autoload "IngredientData".
##
## Cada condição pede uma lista de requisitos. Um requisito é um grupo de ids
## de ingrediente em que basta um: o normal é o grupo ter um id só, e os
## ingredientes marcados com ":ou" na mesma condição formam um grupo único
## (camu-camu ou acerola na anemia ferropriva).

const CSV_PATH := "res://data/ingredientes.csv"
const HEADER := ["id", "nome", "regiao", "paridade", "condicoes"]
const CONDITION_SEPARATOR := "|"
const MODIFIER_SEPARATOR := ":"
const ALTERNATIVE_MODIFIER := "ou"

## id -> Ingredient, na ordem do CSV.
var _ingredients: Dictionary = {}
## id da condição -> Array[PackedStringArray] (requisitos).
var _requirements: Dictionary = {}


func _ready() -> void:
	if not load_csv(CSV_PATH):
		push_error("IngredientData: não foi possível carregar %s" % CSV_PATH)


## Lê o CSV e substitui os dados carregados. Devolve false se o arquivo não
## abrir ou se o cabeçalho for diferente do esperado.
func load_csv(path: String) -> bool:
	_ingredients.clear()
	_requirements.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	if Array(file.get_csv_line()) != HEADER:
		push_error("IngredientData: cabeçalho inesperado em %s" % path)
		return false

	# condição -> ids marcados com ":ou", juntados num grupo só no final.
	var alternatives := {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].strip_edges().is_empty():
			continue
		if row.size() != HEADER.size():
			push_error("IngredientData: linha inválida em %s: %s" % [path, row])
			continue
		var conditions := PackedStringArray()
		for entry in row[4].split(CONDITION_SEPARATOR, false):
			var parts := entry.strip_edges().split(MODIFIER_SEPARATOR)
			var condition := parts[0]
			conditions.append(condition)
			if not _requirements.has(condition):
				_requirements[condition] = [] as Array[PackedStringArray]
			if parts.size() > 1 and parts[1] == ALTERNATIVE_MODIFIER:
				if not alternatives.has(condition):
					alternatives[condition] = PackedStringArray()
				alternatives[condition].append(row[0])
			else:
				_requirements[condition].append(PackedStringArray([row[0]]))
		_ingredients[row[0]] = Ingredient.new(row[0], row[1], row[2], row[3], conditions)

	for condition in alternatives:
		_requirements[condition].append(alternatives[condition])
	return true


## Ingrediente com esse id, ou null se não existir.
func get_ingredient(id: String) -> Ingredient:
	return _ingredients.get(id)


func has_ingredient(id: String) -> bool:
	return _ingredients.has(id)


## Todos os ingredientes, na ordem do CSV.
func get_all_ingredients() -> Array[Ingredient]:
	var result: Array[Ingredient] = []
	result.assign(_ingredients.values())
	return result


## Ingredientes que aparecem nos andares dessa região e paridade ("impar" ou
## "par"), na ordem do CSV.
func get_ingredients_in(region: String, parity: String) -> Array[Ingredient]:
	var result: Array[Ingredient] = []
	for ingredient: Ingredient in _ingredients.values():
		if ingredient.region == region and ingredient.parity == parity:
			result.append(ingredient)
	return result


## Ids de todas as condições, na ordem em que aparecem no CSV.
func get_conditions() -> PackedStringArray:
	return PackedStringArray(_requirements.keys())


## Todos os ingredientes que servem para a condição, incluindo as alternativas.
func get_ingredients_for(condition: String) -> Array[Ingredient]:
	var result: Array[Ingredient] = []
	for group: PackedStringArray in get_requirements(condition):
		for id in group:
			result.append(_ingredients[id])
	return result


## Requisitos da condição: cada item é um grupo de ids em que basta um. Vazio se
## a condição não existir.
func get_requirements(condition: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	result.assign(_requirements.get(condition, []))
	return result


## true se os ingredientes entregues cobrem todos os requisitos da condição.
## Ingredientes a mais não atrapalham.
func is_condition_satisfied(condition: String, ingredient_ids: Array) -> bool:
	if not _requirements.has(condition):
		return false
	for group: PackedStringArray in _requirements[condition]:
		var covered := false
		for id in group:
			if id in ingredient_ids:
				covered = true
				break
		if not covered:
			return false
	return true
