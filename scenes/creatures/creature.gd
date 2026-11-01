class_name Creature
extends CharacterBody2D
## Criatura do labirinto. Fica parada até o gato chegar perto, então persegue e,
## se ele se afastar o bastante, desiste (`CreatureBrain`). O caminho é o menor
## pela grade do andar (`GridBfs`), então ela nunca atravessa parede, e a
## distância de detecção também é medida andando: uma criatura do outro lado de
## uma parede não percebe o gato.
##
## Três arranhões a derrotam, sem sangue: ela pisca, é empurrada para trás e, no
## último, some encolhendo.

## Emitido uma vez, quando a criatura é derrotada.
signal defeated(creature: Creature)

## Segundos entre uma busca de caminho e outra.
const REPATH_INTERVAL := 0.25
const KNOCKBACK_SPEED := 160.0
const KNOCKBACK_SECONDS := 0.12
## Distância (em pixels) a que a criatura considera que chegou à célula-alvo.
const ARRIVAL_DISTANCE := 4.0
const FADE_SECONDS := 0.25

## Velocidade de perseguição, em pixels por segundo.
@export var speed := 70.0
## Distância andando, em pixels, em que ela percebe o gato (5 tiles).
@export var detection_distance := 160.0
## Distância andando, em pixels, em que ela desiste (9 tiles).
@export var give_up_distance := 288.0
## Quantos arranhões a derrotam.
@export var hits_to_defeat := 3

var brain: CreatureBrain
var _grid: MazeGrid
var _target: Node2D
var _path: Array[Vector2i] = []
var _path_index := 0
var _repath_left := 0.0
var _hits_left := 0
var _knockback_left := 0.0
var _knockback := Vector2.ZERO

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	brain = CreatureBrain.new(detection_distance, give_up_distance)
	_hits_left = hits_to_defeat


## Liga a criatura ao andar (grade para achar o caminho) e ao gato (alvo).
func setup(grid: MazeGrid, target: Node2D) -> void:
	_grid = grid
	_target = target


func _physics_process(delta: float) -> void:
	if _grid == null or _target == null:
		return
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback
		move_and_slide()
		return
	_repath_left -= delta
	if _repath_left <= 0.0:
		_repath_left = REPATH_INTERVAL
		_think()
	velocity = _chase_velocity()
	move_and_slide()


## Se já foi derrotada.
func is_defeated() -> bool:
	return _hits_left <= 0


## Recebe um arranhão vindo de `direction` (para onde o golpe empurra).
func take_scratch(direction: Vector2 = Vector2.ZERO) -> void:
	if is_defeated():
		return
	_hits_left -= 1
	_flash()
	if _hits_left <= 0:
		_defeat()
	else:
		_knockback = direction.normalized() * KNOCKBACK_SPEED
		_knockback_left = KNOCKBACK_SECONDS


## Mede a distância andando até o gato, atualiza o estado e refaz o caminho.
func _think() -> void:
	var tile := MazeGrid.TILE_SIZE
	var distance := INF
	_path.clear()
	# A distância andando nunca é menor que a em linha reta: longe demais em
	# linha reta já descarta a busca.
	if global_position.distance_to(_target.global_position) <= give_up_distance + tile:
		var from := MazeGrid.position_to_cell(global_position)
		var to := MazeGrid.position_to_cell(_target.global_position)
		var max_steps := ceili(give_up_distance / tile) + 1
		_path = GridBfs.path(_grid, from, to, max_steps)
		if not _path.is_empty():
			distance = (_path.size() - 1) * tile
	brain.update(distance)
	if not brain.is_chasing():
		_path.clear()
	_path_index = 1


## Anda de célula em célula pelo caminho; na última, vai direto ao gato.
func _chase_velocity() -> Vector2:
	if not brain.is_chasing() or _path.is_empty():
		return Vector2.ZERO
	while _path_index < _path.size() - 1:
		var waypoint := MazeGrid.cell_to_position(_path[_path_index])
		if global_position.distance_to(waypoint) > ARRIVAL_DISTANCE:
			return global_position.direction_to(waypoint) * speed
		_path_index += 1
	return global_position.direction_to(_target.global_position) * speed


func _flash() -> void:
	_sprite.modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.15)


func _defeat() -> void:
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	defeated.emit(self)
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_property(_sprite, "scale", Vector2(0.3, 0.3), FADE_SECONDS)
	tween.chain().tween_callback(queue_free)
