class_name Player
extends CharacterBody2D
## Mingau, o gato controlado pelo jogador. Anda nas quatro direções (e nas
## diagonais) lendo as ações do Input Map, sem acelerar na diagonal, e arranha
## com a ação `attack`: golpe de curto alcance na direção em que ele olha, com um
## pequeno intervalo entre os golpes. Sem armas e sem sangue.

## Emitido a cada arranhão, com a direção do golpe.
signal attacked(direction: Vector2)

## Camada de colisão das criaturas (a 2ª).
const CREATURE_MASK := 2
## Distância do centro do gato até o centro do golpe, em pixels.
const ATTACK_REACH := 26.0
## Tamanho da área do golpe, em pixels.
const ATTACK_SIZE := Vector2(36, 36)

## Velocidade de caminhada, em pixels por segundo.
@export var speed := 160.0
## Intervalo mínimo entre dois arranhões, em segundos.
@export var attack_cooldown := 0.4

## Para onde o gato olha: a última direção em que andou (uma das quatro).
var facing := Vector2.DOWN

var _cooldown_left := 0.0

@onready var _camera: Camera2D = $Camera
@onready var _scratch: ScratchEffect = $Scratch


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	facing = facing_for(direction, facing)
	velocity = velocity_for(direction)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		try_attack()


## Velocidade para uma direção de entrada. O tamanho da direção é limitado a 1,
## então a diagonal não passa de `speed`.
func velocity_for(direction: Vector2) -> Vector2:
	return direction.limit_length(1.0) * speed


## Direção para onde o gato passa a olhar: a das quatro direções mais próxima da
## entrada (na diagonal, vale a horizontal). Sem entrada, continua olhando para
## `current`.
static func facing_for(direction: Vector2, current: Vector2) -> Vector2:
	if direction.is_zero_approx():
		return current
	if absf(direction.x) >= absf(direction.y):
		return Vector2(signf(direction.x), 0.0)
	return Vector2(0.0, signf(direction.y))


## Arranha na direção em que o gato olha. Devolve false se ainda estiver no
## intervalo entre golpes. Cada criatura na área do golpe leva um arranhão.
func try_attack() -> bool:
	if _cooldown_left > 0.0:
		return false
	_cooldown_left = attack_cooldown
	for creature in creatures_in_reach():
		creature.take_scratch(facing)
	_scratch.play(facing)
	attacked.emit(facing)
	return true


## Criaturas dentro da área do golpe agora (a área fica na frente do gato).
func creatures_in_reach() -> Array[Creature]:
	var hitbox := RectangleShape2D.new()
	hitbox.size = ATTACK_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox
	query.transform = Transform2D(0.0, global_position + facing * ATTACK_REACH)
	query.collision_mask = CREATURE_MASK
	query.collide_with_bodies = true
	var found: Array[Creature] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		var creature := hit["collider"] as Creature
		if creature != null and not creature.is_defeated():
			found.append(creature)
	return found


## Impede a câmera de mostrar o que está fora da sala (em pixels do mundo).
func set_camera_limits(room: Rect2i) -> void:
	_camera.limit_left = room.position.x
	_camera.limit_top = room.position.y
	_camera.limit_right = room.end.x
	_camera.limit_bottom = room.end.y
