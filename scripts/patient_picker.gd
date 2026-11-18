class_name PatientPicker
extends RefCounted
## Sorteia o próximo paciente da campanha. Cada paciente chega com uma das 10
## condições, e nenhuma condição se repete: o sorteio é feito entre as que ainda
## não foram atendidas (inclusive para o primeiro paciente). Uma condição só
## entra no sorteio se for possível cumpri-la, isto é, se cada requisito dela tem
## ao menos um ingrediente que aparece em alguma região e paridade.
##
## É só dado, sem cena. O estado da campanha guarda uma instância em
## `GameState.patients`.

## Emitido quando uma condição é marcada como atendida.
signal attended_changed

## Quantos atendimentos a campanha tem, se o projeto não disser outro número.
const DEFAULT_CAMPAIGN_SIZE := 10
## Configuração do projeto que muda o número de atendimentos da campanha
## (Projeto > Configurações do Projeto, com "Configurações avançadas" ligado).
const CAMPAIGN_SIZE_SETTING := "apotegato/campanha/atendimentos"

## Quantos atendimentos a campanha tem. Começa com a configuração do projeto
## e só muda nos testes. Valores fora de 1..(condições possíveis) são
## ajustados por `campaign_goal`.
var campaign_size: int = ProjectSettings.get_setting(CAMPAIGN_SIZE_SETTING, DEFAULT_CAMPAIGN_SIZE)

## Condições já atendidas, na ordem do atendimento.
var _attended: Array[String] = []


## Sorteia a próxima condição entre as ainda não atendidas e possíveis. Não
## marca nada como atendido: quem atende chama `mark_attended`. Devolve "" se
## não sobrou nenhuma.
func pick(rng: RandomNumberGenerator) -> String:
	var candidates := remaining()
	if candidates.is_empty():
		return ""
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## Sorteio do modo contínuo, depois dos 10 atendimentos da campanha: qualquer
## uma das condições possíveis pode voltar. Se `previous` (a condição do
## paciente anterior) não for a única possível, ela não repete em seguida.
func pick_continuous(rng: RandomNumberGenerator, previous: String = "") -> String:
	var candidates: Array[String] = []
	for condition in IngredientData.get_conditions():
		if is_feasible(condition) and condition != previous:
			candidates.append(condition)
	if candidates.is_empty():
		return previous if is_feasible(previous) else ""
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## true quando a campanha chegou ao número de atendimentos (ou quando não
## sobrou condição possível) e começa o encerramento.
func is_campaign_complete() -> bool:
	return not _attended.is_empty() and _attended.size() >= campaign_goal()


## Quantos atendimentos fecham a campanha: `campaign_size`, limitado entre 1 e
## o número de condições possíveis (não dá para atender mais que isso sem
## repetir).
func campaign_goal() -> int:
	var feasible := 0
	for condition in IngredientData.get_conditions():
		if is_feasible(condition):
			feasible += 1
	return clampi(campaign_size, 1, maxi(feasible, 1))


## Condições que ainda podem ser sorteadas: não atendidas e possíveis, na
## ordem do CSV.
func remaining() -> Array[String]:
	var result: Array[String] = []
	for condition in IngredientData.get_conditions():
		if condition not in _attended and is_feasible(condition):
			result.append(condition)
	return result


## Marca a condição como atendida. Devolve false se o id for desconhecido ou se
## ela já tinha sido atendida.
func mark_attended(condition: String) -> bool:
	if condition in _attended or condition not in IngredientData.get_conditions():
		return false
	_attended.append(condition)
	attended_changed.emit()
	return true


func is_attended(condition: String) -> bool:
	return condition in _attended


## Quantos pacientes já foram atendidos.
func attended_count() -> int:
	return _attended.size()


## Condições atendidas, na ordem do atendimento.
func attended() -> Array[String]:
	return _attended.duplicate()


## Recomeça a campanha: nenhuma condição atendida.
func reset() -> void:
	if _attended.is_empty():
		return
	_attended.clear()
	attended_changed.emit()


## true se todos os requisitos da condição têm ao menos um ingrediente que
## aparece em alguma região e paridade. Sem isso o paciente seria um objetivo
## impossível.
static func is_feasible(condition: String) -> bool:
	var requirements := IngredientData.get_requirements(condition)
	if requirements.is_empty():
		return false
	for group: PackedStringArray in requirements:
		var found := false
		for id in group:
			var ingredient := IngredientData.get_ingredient(id)
			if (
				ingredient != null
				and ingredient.region in Regions.IDS
				and ingredient.parity in [GameState.PARITY_ODD, GameState.PARITY_EVEN]
			):
				found = true
				break
		if not found:
			return false
	return true
