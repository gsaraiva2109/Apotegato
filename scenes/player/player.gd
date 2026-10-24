class_name Player
extends CharacterBody2D
## Mingau, o gato controlado pelo jogador. Anda nas quatro direções (e nas
## diagonais) lendo as ações do Input Map, sem acelerar na diagonal.

## Velocidade de caminhada, em pixels por segundo.
@export var speed := 160.0

@onready var _camera: Camera2D = $Camera


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = velocity_for(direction)
	move_and_slide()


## Velocidade para uma direção de entrada. O tamanho da direção é limitado a 1,
## então a diagonal não passa de `speed`.
func velocity_for(direction: Vector2) -> Vector2:
	return direction.limit_length(1.0) * speed


## Impede a câmera de mostrar o que está fora da sala (em pixels do mundo).
func set_camera_limits(room: Rect2i) -> void:
	_camera.limit_left = room.position.x
	_camera.limit_top = room.position.y
	_camera.limit_right = room.end.x
	_camera.limit_bottom = room.end.y
