class_name GameFlow
extends RefCounted
## Máquina de estados do jogo: em que modo o jogo está agora. Só na exploração o
## Mingau anda, ataca e interage; nos outros estados o jogo fica congelado e só a
## interface (caixa de diálogo, menus, mochila) responde.
##
## As transições permitidas estão em `TRANSITIONS`; qualquer outra é recusada e
## não muda nada. Quem congela a cena é o `GameState`, que escuta
## `state_changed`; aqui é só a regra, sem cena.

## Emitido a cada mudança de estado.
signal state_changed(from: State, to: State)

enum State {
	## O gato anda, ataca e interage. Único estado em que o jogo roda.
	EXPLORATION,
	## Uma conversa na caixa de diálogo.
	DIALOGUE,
	## A mochila aberta para entregar ingredientes à apotecária.
	DELIVERY,
	## Um menu aberto: porta, regiões, estoque, mochila só para ver e diário.
	MENU,
	## A campanha principal terminou com a volta para a Unifor.
	COMPLETION,
}

## Estado de origem -> estados de destino permitidos.
const TRANSITIONS := {
	State.EXPLORATION: [State.DIALOGUE, State.DELIVERY, State.MENU],
	State.DIALOGUE: [State.EXPLORATION, State.DELIVERY, State.COMPLETION],
	State.DELIVERY: [State.DIALOGUE, State.EXPLORATION],
	State.MENU: [State.EXPLORATION],
	State.COMPLETION: [],
}

## Nome de cada estado, para as mensagens de aviso.
const STATE_NAMES := {
	State.EXPLORATION: "exploração",
	State.DIALOGUE: "diálogo",
	State.DELIVERY: "entrega",
	State.MENU: "menu",
	State.COMPLETION: "conclusão",
}

var state: State = State.EXPLORATION


## Muda para `to` se a transição for permitida. Devolve false (e avisa) se não
## for. Pedir o estado atual não faz nada e devolve false.
func request(to: State) -> bool:
	if not can_change_to(to):
		if to != state:
			push_warning("Transição recusada: %s -> %s" % [STATE_NAMES[state], STATE_NAMES[to]])
		return false
	var from := state
	state = to
	state_changed.emit(from, to)
	return true


## Se a transição do estado atual para `to` está na tabela.
func can_change_to(to: State) -> bool:
	return to in TRANSITIONS[state]


## Abre um menu. Só a partir da exploração.
func open_menu() -> bool:
	return request(State.MENU)


## Fecha o menu aberto e volta à exploração. Fora de um menu não faz nada.
func close_menu() -> bool:
	if state != State.MENU:
		return false
	return request(State.EXPLORATION)


## Se o Mingau pode andar, atacar e interagir.
func can_player_act() -> bool:
	return state == State.EXPLORATION


## Se a cena do jogo deve ficar congelada (tudo fora da exploração).
func is_frozen() -> bool:
	return state != State.EXPLORATION


func is_in(which: State) -> bool:
	return state == which


## Volta à exploração sem passar pela tabela. Para recomeçar a campanha e para
## quando uma cena nova abre (cabana ou andar), que sempre começa explorando.
func reset() -> void:
	if state == State.EXPLORATION:
		return
	var from := state
	state = State.EXPLORATION
	state_changed.emit(from, state)
