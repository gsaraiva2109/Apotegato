class_name CreatureBrain
extends RefCounted
## Máquina de estados de uma criatura: "não percebeu" (parada) e "perseguindo".
## Ela passa a perseguir quando o gato chega perto (distância de detecção) e
## desiste quando ele se afasta o bastante (distância de desistência). Como a
## desistência é maior que a detecção, a criatura não fica alternando de estado
## na fronteira.
##
## As distâncias são em pixels e quem usa decide o que medir (a criatura mede o
## caminho andando, então paredes contam). É só lógica, sem cena.

enum State { UNAWARE, CHASING }

## Distância em que uma criatura que não percebeu passa a perseguir.
var detection_distance: float
## Distância em que uma criatura perseguindo desiste. Nunca menor que a de
## detecção.
var give_up_distance: float
var state: State = State.UNAWARE


func _init(p_detection_distance: float = 160.0, p_give_up_distance: float = 288.0) -> void:
	detection_distance = p_detection_distance
	give_up_distance = maxf(p_give_up_distance, p_detection_distance)


## Atualiza o estado com a distância atual até o gato (`INF` se não dá para
## chegar nele) e devolve o estado novo.
func update(distance: float) -> State:
	match state:
		State.UNAWARE:
			if distance <= detection_distance:
				state = State.CHASING
		State.CHASING:
			if distance >= give_up_distance:
				state = State.UNAWARE
	return state


func is_chasing() -> bool:
	return state == State.CHASING
