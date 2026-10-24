extends Node2D
## Sala provisória para testar o movimento do Mingau e a câmera. Será trocada
## pela cabana de verdade; serve de modelo para limitar a câmera ao mapa.

## Tamanho da sala em pixels (30 x 20 tiles de 32 px).
const ROOM := Rect2i(0, 0, 960, 640)

@onready var _player: Player = $Player


func _ready() -> void:
	_player.set_camera_limits(ROOM)
