class_name ScratchEffect
extends Node2D
## O efeito visual do arranhão: três riscos paralelos na frente do gato, que
## somem em instantes. Sem sangue.

const DURATION := 0.18
const REACH := 26.0
const LENGTH := 22.0
const SPACING := 7.0
const COLOR := Color(0.95, 0.9, 0.77)

var _direction := Vector2.DOWN
var _time_left := 0.0


func _ready() -> void:
	hide()


func _process(delta: float) -> void:
	if _time_left <= 0.0:
		return
	_time_left -= delta
	if _time_left <= 0.0:
		hide()
	queue_redraw()


## Mostra os riscos na direção em que o gato olha.
func play(direction: Vector2) -> void:
	_direction = direction
	_time_left = DURATION
	show()
	queue_redraw()


## Se o efeito está na tela.
func is_playing() -> bool:
	return _time_left > 0.0


func _draw() -> void:
	if _time_left <= 0.0:
		return
	var color := COLOR
	color.a = clampf(_time_left / DURATION, 0.0, 1.0)
	var side := _direction.orthogonal()
	var center := _direction * REACH
	for i in range(-1, 2):
		var offset := side * (i * SPACING)
		# os riscos são inclinados, como garras
		var start := center + offset - _direction * LENGTH * 0.5 - side * 3.0
		var end := center + offset + _direction * LENGTH * 0.5 + side * 3.0
		draw_line(start, end, color, 2.0)
