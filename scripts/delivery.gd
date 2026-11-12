class_name Delivery
extends RefCounted
## A entrega de ingredientes à apotecária para a condição de um paciente.
##
## Regras (roteiro, seção 1.3 e 5):
## - Dá para entregar mesmo sem ter tudo. O que serve à condição vai para o
##   estoque da apotecária e conta nas entregas seguintes; ela diz o que falta.
## - Com a mochila vazia (e sem que o estoque já cubra a condição), nada acontece
##   além do aviso.
## - Quando mochila e estoque cobrem todos os requisitos (um id por grupo "ou"),
##   a entrega se completa e um de cada requisito é gasto.
## - O que sobra na mochila não serve a este paciente: cada sobra pode ser
##   guardada no estoque ou usada para recuperar vida.
##
## É só dado, sem cena: a tela da mochila chama `deliver()` e mostra o resultado.

enum Outcome {
	## A mochila está vazia (e o estoque não completa a condição).
	EMPTY_BACKPACK,
	## Entregou, mas ainda faltam ingredientes.
	PARTIAL,
	## Todos os requisitos foram cobertos.
	COMPLETE,
}

## Quantos meios corações uma sobra recupera (um coração inteiro).
const HALVES_PER_SURPLUS := Hearts.HALVES_PER_HEART

## Id da condição do paciente atual (o mesmo do CSV).
var condition: String
var backpack: Backpack
var stock: Stock
var _completed := false


func _init(condition_id: String, source_backpack: Backpack, source_stock: Stock) -> void:
	condition = condition_id
	backpack = source_backpack
	stock = source_stock


## Faz a entrega. Devolve um `DeliveryResult` e já aplica as mudanças na mochila
## e no estoque.
func deliver() -> DeliveryResult:
	var result := DeliveryResult.new()
	var requirements := IngredientData.get_requirements(condition)
	if requirements.is_empty():
		result.outcome = Outcome.EMPTY_BACKPACK
		return result

	# O que já está coberto só pelo estoque, antes de mexer em qualquer coisa.
	var covered_by_stock := _missing_groups(requirements, false).is_empty()
	if backpack.is_empty() and not covered_by_stock:
		result.outcome = Outcome.EMPTY_BACKPACK
		result.missing = _missing_groups(requirements, false)
		return result

	# Passa para o estoque uma unidade do que serve a cada requisito ainda não
	# coberto por ele.
	for group in requirements:
		if _group_covered_by_stock(group):
			continue
		for id in group:
			if backpack.count(id) > 0 and backpack.remove(id):
				stock.store(id)
				result.stored.append(id)
				break

	result.missing = _missing_groups(requirements, false)
	if not result.missing.is_empty():
		result.outcome = Outcome.PARTIAL
		result.surplus = surplus()
		return result

	# Completo: gasta um de cada requisito.
	for group in requirements:
		for id in group:
			if stock.take(id):
				result.consumed.append(id)
				break
	_completed = true
	result.outcome = Outcome.COMPLETE
	result.surplus = surplus()
	return result


## Requisitos que ainda faltam considerando mochila e estoque, sem entregar nada.
func missing() -> Array[PackedStringArray]:
	return _missing_groups(IngredientData.get_requirements(condition), true)


## Se mochila e estoque juntos já cobrem a condição.
func can_complete() -> bool:
	return not IngredientData.get_requirements(condition).is_empty() and missing().is_empty()


## id -> quantidade das sobras: o que está na mochila e não serve à condição.
## Depois que a entrega se completa, tudo o que restou na mochila é sobra (inclusive
## a alternativa "ou" que não foi usada).
func surplus() -> Dictionary:
	var needed: Array[String] = []
	if not _completed:
		for group in IngredientData.get_requirements(condition):
			for id in group:
				needed.append(id)
	var result := {}
	for id in backpack.ids():
		if id not in needed:
			result[id] = backpack.count(id)
	return result


## Guarda uma unidade da sobra no estoque.
func store_surplus(id: String) -> bool:
	if not surplus().has(id) or not backpack.remove(id):
		return false
	stock.store(id)
	return true


## Usa uma unidade da sobra para recuperar vida. Só gasta o ingrediente se
## recuperou de fato (com a vida cheia, a sobra fica na mochila). Se falta só meio
## coração, cura esse meio e gasta o ingrediente do mesmo jeito. Devolve quantos
## meios corações recuperou (0, 1 ou 2).
func use_surplus(id: String, hearts: Hearts) -> int:
	if hearts == null or hearts.is_full() or not surplus().has(id):
		return 0
	if not backpack.remove(id):
		return 0
	return hearts.heal(HALVES_PER_SURPLUS)


## Nomes legíveis dos requisitos que faltam, como "Camu-Camu ou Acerola".
static func group_label(group: PackedStringArray) -> String:
	var names: Array[String] = []
	for id in group:
		var ingredient := IngredientData.get_ingredient(id)
		names.append(ingredient.display_name if ingredient != null else id)
	return " ou ".join(names)


## Lista em português: "A", "A e B", "A, B e C".
static func join_labels(labels: Array[String]) -> String:
	if labels.size() <= 1:
		return "".join(labels)
	return "%s e %s" % [", ".join(labels.slice(0, labels.size() - 1)), labels[-1]]


func _group_covered_by_stock(group: PackedStringArray) -> bool:
	for id in group:
		if stock.count(id) > 0:
			return true
	return false


func _missing_groups(
	requirements: Array[PackedStringArray], include_backpack: bool
) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for group in requirements:
		var covered := _group_covered_by_stock(group)
		if not covered and include_backpack:
			for id in group:
				if backpack.count(id) > 0:
					covered = true
					break
		if not covered:
			result.append(group)
	return result
