class_name Cabin
extends Node2D
## A cabana da apotecária: sala de 30 x 17 tiles onde o Mingau anda e de onde
## partem a porta para as regiões, o diário e o atendimento do paciente.

## Emitido quando o Mingau interage com um ponto da cabana (`door`,
## `journal` ou `patient`). As próximas sprints ligam cada ponto a uma tela.
signal interacted(id: StringName)

## Tamanho da cabana em pixels (30 x 17 tiles de 32 px).
const ROOM := Rect2i(0, 0, 960, 544)

@onready var _player: Player = $World/Player


func _ready() -> void:
	_player.set_camera_limits(ROOM)
	for area: InteractionArea in $Interactions.get_children():
		area.interacted.connect(interacted.emit)
