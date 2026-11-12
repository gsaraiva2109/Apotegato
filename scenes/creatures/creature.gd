class_name Creature
extends CharacterBody2D
## Criatura do labirinto. Fica parada até o gato chegar perto, então persegue e,
## se ele se afastar o bastante, desiste (`CreatureBrain`). O caminho é o menor
## pela grade do andar (`GridBfs`), então ela nunca atravessa parede, e a
## distância de detecção também é medida andando: uma criatura do outro lado de
## uma parede não percebe o gato.
##
## Encostar nela não machuca. Com o gato ao alcance, ela para e avisa (pisca em
## vermelho e dá um pulinho), trava a direção, dá o bote e descansa. Só o bote
## tira vida do gato (`Player.take_hit`), e só se ele estiver na área do golpe.
## Um arranhão durante o aviso cancela o bote. Gato desmaiado não é atacado.
##
## Todo tempo daqui (aviso, bote, descanso, empurrão) conta no `_physics_process`
## com o `delta`, sem Timer, então congela junto com o jogo. O combate nunca
## pausa a árvore de cenas.
##
## Três arranhões a derrotam (a quantidade vem do catálogo), sem sangue: ela
## pisca, é empurrada para trás e, no último, some encolhendo.

## Emitido uma vez, quando a criatura é derrotada.
signal defeated(creature: Creature)

## Segundos entre uma busca de caminho e outra.
const REPATH_INTERVAL := 0.25
## Distância (em pixels) a que a criatura considera que chegou à célula-alvo.
const ARRIVAL_DISTANCE := 4.0
const FADE_SECONDS := 0.25
## Deslocamento do centro do corpo e da área do golpe em relação à origem.
const BODY_OFFSET := Vector2(0, 4)
## Quantas piscadas vermelhas o aviso tem.
const WARNING_BLINKS := 3
## Altura do pulinho do aviso, em pixels.
const WARNING_HOP_HEIGHT := 4.0
## Cor do sprite no pico da piscada do aviso.
const WARNING_COLOR := Color(1.8, 0.35, 0.35)
## Provisório da criatura forte, até a arte própria (#38): maior e mais escura.
const STRONG_SCALE := 1.25
const STRONG_TINT := Color(0.55, 0.45, 0.55)

## Velocidade de perseguição, em pixels por segundo.
@export var speed := 70.0
## Distância andando, em pixels, em que ela percebe o gato (5 tiles).
@export var detection_distance := 160.0
## Distância andando, em pixels, em que ela desiste (9 tiles).
@export var give_up_distance := 288.0
## Quantos arranhões a derrotam.
@export var hits_to_defeat := 3
## Quantos meios corações o bote tira do gato.
@export var damage := 1
## Distância em linha reta, em pixels, a que ela para e avisa.
@export var attack_range := 24.0
## Duração do aviso antes do bote, em segundos.
@export var warning_seconds := 0.4
## Duração do bote, em segundos.
@export var lunge_seconds := 0.12
## Velocidade do bote, em pixels por segundo.
@export var lunge_speed := 160.0
## Descanso depois do bote, em segundos.
@export var rest_seconds := 0.7
## Quanto a área do golpe avança além do corpo, na direção do bote, em pixels.
@export var strike_reach := 8.0
## Velocidade do empurrão ao ser arranhada, em pixels por segundo.
@export var knockback_speed := 160.0
## Duração do empurrão ao ser arranhada, em segundos.
@export var knockback_seconds := 0.12

var brain: CreatureBrain
## Id da criatura no catálogo (vazio se veio sem dados).
var creature_id := ""
var _grid: MazeGrid
var _target: Node2D
var _path: Array[Vector2i] = []
var _path_index := 0
var _repath_left := 0.0
var _hits_left := 0
var _knockback_left := 0.0
var _knockback := Vector2.ZERO
var _strike_direction := Vector2.DOWN
var _lunge_connected := false
var _strong := false
var _base_color := Color.WHITE

@onready var _sprite: Sprite2D = $Sprite
@onready var _strike_area: Area2D = $StrikeArea


func _ready() -> void:
	brain = CreatureBrain.new(
		detection_distance,
		give_up_distance,
		attack_range,
		warning_seconds,
		lunge_seconds,
		rest_seconds
	)
	_hits_left = hits_to_defeat
	_strike_area.position = BODY_OFFSET
	if _strong:
		_base_color = STRONG_TINT
		_sprite.scale = Vector2.ONE * STRONG_SCALE
		_sprite.modulate = _base_color


## Liga a criatura ao andar (grade para achar o caminho) e ao gato (alvo). Com
## `data`, assume dano, arranhões e velocidade da criatura do catálogo; chame
## antes de pôr a criatura na árvore.
func setup(grid: MazeGrid, target: Node2D, data: CreatureCatalog.Entry = null) -> void:
	_grid = grid
	_target = target
	if data != null:
		creature_id = data.id
		damage = data.damage
		hits_to_defeat = data.hits
		speed = data.speed
		_strong = data.is_strong()
	_hits_left = hits_to_defeat


func _physics_process(delta: float) -> void:
	if _grid == null or _target == null:
		return
	var before := brain.state
	var current := brain.tick(
		delta, global_position.distance_to(_target.global_position), _target_can_be_hit()
	)
	if current != before:
		_on_state_changed(before, current)
	if current == CreatureBrain.State.WARNING:
		_set_telegraph(brain.warning_progress())
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback
	else:
		if not brain.is_attacking():
			_repath_left -= delta
			if _repath_left <= 0.0:
				_repath_left = REPATH_INTERVAL
				_think()
		velocity = _velocity_for(brain.state)
	move_and_slide()
	if brain.can_hurt():
		_hurt_in_strike_area()


## Se já foi derrotada.
func is_defeated() -> bool:
	return _hits_left <= 0


## Recebe um arranhão vindo de `direction` (para onde o golpe empurra).
func take_scratch(direction: Vector2 = Vector2.ZERO) -> void:
	if is_defeated():
		return
	_hits_left -= 1
	if brain.state == CreatureBrain.State.WARNING:
		_clear_telegraph()
		_strike_area.position = BODY_OFFSET
	brain.scratched()
	_flash()
	if _hits_left <= 0:
		_defeat()
	else:
		_knockback = direction.normalized() * knockback_speed
		_knockback_left = knockback_seconds


## Mede a distância andando até o gato, atualiza o estado e refaz o caminho.
func _think() -> void:
	var tile := MazeGrid.TILE_SIZE
	var distance := INF
	_path.clear()
	# A distância andando nunca é menor que a em linha reta: longe demais em
	# linha reta já descarta a busca. Gato desmaiado não é percebido.
	if (
		_target_can_be_hit()
		and global_position.distance_to(_target.global_position) <= give_up_distance + tile
	):
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


## Velocidade em cada estado: só persegue e dá o bote; nos outros fica parada.
func _velocity_for(state: CreatureBrain.State) -> Vector2:
	match state:
		CreatureBrain.State.CHASING:
			return _chase_velocity()
		CreatureBrain.State.LUNGE:
			return _strike_direction * lunge_speed
	return Vector2.ZERO


## Se o alvo pode levar um golpe (o gato desmaiado não pode).
func _target_can_be_hit() -> bool:
	return not (_target is Player and (_target as Player).is_fainted())


func _on_state_changed(before: CreatureBrain.State, current: CreatureBrain.State) -> void:
	match current:
		CreatureBrain.State.WARNING:
			# A direção do bote fica travada aqui, e a área do golpe já aponta para ela.
			_strike_direction = global_position.direction_to(_target.global_position)
			if _strike_direction.is_zero_approx():
				_strike_direction = Vector2.DOWN
			_strike_area.position = BODY_OFFSET + _strike_direction * strike_reach
		CreatureBrain.State.LUNGE:
			_clear_telegraph()
			_lunge_connected = false
		CreatureBrain.State.REST, CreatureBrain.State.UNAWARE:
			_clear_telegraph()
			_strike_area.position = BODY_OFFSET
		CreatureBrain.State.CHASING:
			# Voltando do descanso, o caminho antigo não vale mais.
			if before == CreatureBrain.State.REST:
				_repath_left = 0.0


## Tira vida do gato se ele estiver na área do golpe. Cada bote acerta uma vez.
func _hurt_in_strike_area() -> void:
	if _lunge_connected:
		return
	for body in _strike_area.get_overlapping_bodies():
		if body is Player and (body as Player).take_hit(damage, global_position):
			_lunge_connected = true
			return


## Aviso: pisca em vermelho e dá um pulinho, de acordo com o quanto já passou.
func _set_telegraph(progress: float) -> void:
	var pulse := 0.5 - 0.5 * cos(progress * TAU * WARNING_BLINKS)
	_sprite.modulate = _base_color.lerp(WARNING_COLOR, pulse)
	_sprite.position.y = -sin(progress * PI) * WARNING_HOP_HEIGHT


func _clear_telegraph() -> void:
	_sprite.modulate = _base_color
	_sprite.position = Vector2.ZERO


func _flash() -> void:
	_sprite.modulate = Color(3.0, 3.0, 3.0)
	create_tween().tween_property(_sprite, "modulate", _base_color, 0.15)


func _defeat() -> void:
	collision_layer = 0
	collision_mask = 0
	set_physics_process(false)
	defeated.emit(self)
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "modulate:a", 0.0, FADE_SECONDS)
	tween.tween_property(_sprite, "scale", Vector2(0.3, 0.3), FADE_SECONDS)
	tween.chain().tween_callback(queue_free)
