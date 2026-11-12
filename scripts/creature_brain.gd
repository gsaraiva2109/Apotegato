class_name CreatureBrain
extends RefCounted
## Máquina de estados de uma criatura. Ela fica parada até o gato chegar perto
## (distância de detecção), persegue, e quando chega ao alcance do ataque faz
## três coisas em sequência: avisa, dá o bote e descansa.
##
##   parada -> perseguindo -> aviso -> bote -> descanso -> perseguindo
##
## - O aviso é o tempo para o jogador reagir. A direção do bote é travada nele.
## - Só o bote tira vida (`can_hurt`).
## - Arranhar a criatura durante o aviso cancela o bote e a manda ao descanso.
## - Gato desmaiado não é atacado: a criatura volta a ficar parada.
##
## A desistência é maior que a detecção, então a criatura não fica alternando de
## estado na fronteira. As distâncias de percepção são em pixels e quem usa decide
## o que medir (a criatura mede o caminho andando, então paredes contam). Todo
## tempo vem do `delta` de quem chama `tick`, nunca de um Timer, então congela
## junto com o jogo. É só lógica, sem cena.

enum State { UNAWARE, CHASING, WARNING, LUNGE, REST }

## Distância em que uma criatura que não percebeu passa a perseguir.
var detection_distance: float
## Distância em que uma criatura perseguindo desiste. Nunca menor que a de
## detecção.
var give_up_distance: float
## Distância em linha reta, até o gato, em que a criatura começa o aviso.
var attack_range: float
## Duração do aviso, em segundos.
var warning_seconds: float
## Duração do bote, em segundos.
var lunge_seconds: float
## Duração do descanso depois do bote, em segundos.
var rest_seconds: float
var state: State = State.UNAWARE

var _time_left := 0.0


func _init(
	p_detection_distance: float = 160.0,
	p_give_up_distance: float = 288.0,
	p_attack_range: float = 24.0,
	p_warning_seconds: float = 0.4,
	p_lunge_seconds: float = 0.12,
	p_rest_seconds: float = 0.7
) -> void:
	detection_distance = p_detection_distance
	give_up_distance = maxf(p_give_up_distance, p_detection_distance)
	attack_range = p_attack_range
	warning_seconds = p_warning_seconds
	lunge_seconds = p_lunge_seconds
	rest_seconds = p_rest_seconds


## Atualiza a percepção com a distância atual até o gato (`INF` se não dá para
## chegar nele) e devolve o estado novo. Só mexe em "parada" e "perseguindo": no
## meio de um ataque a criatura não larga o gato.
func update(distance: float) -> State:
	match state:
		State.UNAWARE:
			if distance <= detection_distance:
				state = State.CHASING
		State.CHASING:
			if distance >= give_up_distance:
				state = State.UNAWARE
	return state


## Avança o ataque em `delta` segundos. `target_distance` é a distância em linha
## reta até o gato e `target_can_be_hit` é false com o gato desmaiado. Devolve o
## estado novo.
func tick(delta: float, target_distance: float, target_can_be_hit: bool = true) -> State:
	if not target_can_be_hit:
		state = State.UNAWARE
		return state
	match state:
		State.CHASING:
			if target_distance <= attack_range:
				_enter(State.WARNING, warning_seconds)
		State.WARNING:
			_time_left -= delta
			if _time_left <= 0.0:
				_enter(State.LUNGE, lunge_seconds)
		State.LUNGE:
			_time_left -= delta
			if _time_left <= 0.0:
				_enter(State.REST, rest_seconds)
		State.REST:
			_time_left -= delta
			if _time_left <= 0.0:
				state = State.CHASING
	return state


## A criatura levou um arranhão: durante o aviso, o bote é cancelado e ela vai
## direto ao descanso. Nos outros estados não muda nada.
func scratched() -> void:
	if state == State.WARNING:
		_enter(State.REST, rest_seconds)


## Se o golpe da criatura tira vida agora: só durante o bote.
func can_hurt() -> bool:
	return state == State.LUNGE


## Quanto do aviso já passou, de 0 a 1 (0 fora do aviso).
func warning_progress() -> float:
	if state != State.WARNING or warning_seconds <= 0.0:
		return 0.0
	return clampf(1.0 - _time_left / warning_seconds, 0.0, 1.0)


## Se já percebeu o gato: perseguindo ou no meio de um ataque.
func is_chasing() -> bool:
	return state != State.UNAWARE


## Se está no meio de um ataque (aviso, bote ou descanso).
func is_attacking() -> bool:
	return state == State.WARNING or state == State.LUNGE or state == State.REST


func _enter(new_state: State, seconds: float) -> void:
	state = new_state
	_time_left = seconds
