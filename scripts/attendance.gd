class_name Attendance
extends RefCounted
## O atendimento na cabana, seguindo o roteiro (Roteiro_Mingau, seções 1 a 4):
## a introdução da primeira visita, o paciente atual e em que ponto do
## atendimento ele está. Diz qual conversa toca a cada interação; quem mostra a
## conversa é a cabana.
##
## As conversas são devolvidas como tópicos: os ids gerais de
## `data/dialogos.json` (`INTRO`, `PATIENT_REMINDER`...) ou as partes da condição
## atual em `data/atendimentos.json` (`COMPLAINT`, `REQUEST`, `GUIDANCE`,
## `THANKS`).
##
## É só dado, sem cena. O estado da campanha guarda uma instância em
## `GameState.attendance`.

## Emitido sempre que a fase, o paciente ou a introdução mudam.
signal changed

enum Phase {
	## Nenhum paciente na cabana.
	NONE,
	## O paciente chegou e o Mingau ainda não falou com ele.
	ARRIVED,
	## O Mingau ouviu a queixa; a apotecária ainda não pediu os ingredientes.
	HEARD,
	## A apotecária pediu os ingredientes: agora é buscar e entregar.
	REQUESTED,
	## O atendimento foi concluído e o paciente está saindo da cabana.
	LEAVING,
}

## Conversas gerais (`data/dialogos.json`).
const INTRO := "intro"
const PATIENT_REMINDER := "patient_reminder"
const DELIVERY_PARTIAL := "delivery_partial"
const DELIVERY_EXTRAS := "delivery_extras"
const DELIVERY_EMPTY := "delivery_empty"
const ENDING := "ending"
const ENDING_GO_HOME := "ending_go_home"
const ENDING_KEEP_HELPING := "ending_keep_helping"

## Partes de cada condição (`data/atendimentos.json`).
const COMPLAINT := "complaint"
const REQUEST := "request"
const GUIDANCE := "guidance"
const THANKS := "thanks"

## Ids das opções da escolha final.
const CHOICE_GO_HOME := "go_home"
const CHOICE_KEEP_HELPING := "keep_helping"

## A conversa introdutória já aconteceu (só acontece uma vez por campanha).
var intro_done := false
## Condição do paciente que está na cabana (id do CSV), ou "" sem paciente.
var condition: String = ""
var phase: Phase = Phase.NONE
## Depois de "Continuar ajudando": os pacientes vêm do sorteio contínuo.
var continuous := false
## Condição do último paciente atendido, para o sorteio contínuo não repetir.
var last_condition: String = ""


## Se a introdução ainda precisa tocar (primeira vez na cabana).
func needs_intro() -> bool:
	return not intro_done


func finish_intro() -> void:
	if intro_done:
		return
	intro_done = true
	changed.emit()


## Um paciente novo entra na cabana com essa condição.
func arrive(new_condition: String) -> void:
	condition = new_condition
	phase = Phase.ARRIVED
	changed.emit()


## Se há um paciente que ainda aceita conversa (não está saindo).
func has_patient() -> bool:
	return phase in [Phase.ARRIVED, Phase.HEARD, Phase.REQUESTED]


## O Mingau fala com o paciente. Na primeira vez ele conta a queixa e a fase
## avança; depois, até a conclusão, repete a queixa. Sem paciente (ou com ele
## saindo), não há conversa.
func talk_to_patient() -> Array[String]:
	if not has_patient():
		return []
	if phase == Phase.ARRIVED:
		phase = Phase.HEARD
		changed.emit()
	return [COMPLAINT]


## O Mingau fala com a apotecária. Antes de ouvir o paciente, ela lembra que ele
## está esperando; depois, pede os ingredientes (uma vez só). Com o pedido
## feito, falar com ela abre a entrega: veja `can_deliver`.
func talk_to_apothecary() -> Array[String]:
	match phase:
		Phase.ARRIVED:
			return [PATIENT_REMINDER]
		Phase.HEARD:
			phase = Phase.REQUESTED
			changed.emit()
			return [REQUEST]
		Phase.REQUESTED:
			return [REQUEST]
	return []


## Se a entrega está aberta: a apotecária já pediu os ingredientes.
func can_deliver() -> bool:
	return phase == Phase.REQUESTED


## Condição que a mochila usa para entregar: a do paciente, só depois do pedido.
func delivery_condition() -> String:
	return condition if can_deliver() else ""


## Conversas depois de uma entrega, conforme o resultado (`Delivery.Outcome`):
## - mochila vazia: a fala da seção 5.3;
## - sobras que não servem a este paciente: a fala do estoque (5.2), antes das
##   outras;
## - algo útil entregue, mas ainda faltando: a entrega parcial (5.1);
## - tudo entregue: a orientação da apotecária e o agradecimento do paciente.
## `stored_something` diz se algum ingrediente útil saiu da mochila nesta entrega.
func delivery_topics(
	outcome: Delivery.Outcome, stored_something: bool, has_surplus: bool
) -> Array[String]:
	var topics: Array[String] = []
	if outcome == Delivery.Outcome.EMPTY_BACKPACK:
		topics.append(DELIVERY_EMPTY)
		return topics
	if has_surplus:
		topics.append(DELIVERY_EXTRAS)
	if outcome == Delivery.Outcome.COMPLETE:
		topics.append_array([GUIDANCE, THANKS])
	elif stored_something or not has_surplus:
		topics.append(DELIVERY_PARTIAL)
	return topics


## O agradecimento terminou: o atendimento está concluído e o paciente começa a
## sair. Devolve a condição atendida ("" se não havia atendimento em andamento).
func conclude() -> String:
	if not has_patient():
		return ""
	var done := condition
	last_condition = condition
	phase = Phase.LEAVING
	changed.emit()
	return done


## O paciente saiu completamente da cabana. Só depois disso o próximo entra.
func patient_left() -> void:
	condition = ""
	phase = Phase.NONE
	changed.emit()


## Se é a hora do encerramento: todos os atendimentos da campanha concluídos,
## ninguém na cabana e o jogador ainda não escolheu continuar.
func is_ending_due(patients: PatientPicker) -> bool:
	return intro_done and not continuous and phase == Phase.NONE and patients.is_campaign_complete()


## Sorteia o próximo paciente: entre as condições não atendidas na campanha, ou
## qualquer uma no modo contínuo. Devolve "" se não há quem chamar.
func next_condition(patients: PatientPicker, rng: RandomNumberGenerator) -> String:
	if continuous:
		return patients.pick_continuous(rng, last_condition)
	return patients.pick(rng)


## O jogador escolheu "Continuar ajudando" no encerramento.
func start_continuous() -> void:
	continuous = true
	changed.emit()


## Recomeça para uma campanha nova.
func reset() -> void:
	intro_done = false
	condition = ""
	phase = Phase.NONE
	continuous = false
	last_condition = ""
	changed.emit()
