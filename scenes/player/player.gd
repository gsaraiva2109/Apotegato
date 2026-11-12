class_name Player
extends CharacterBody2D
## Mingau, o gato controlado pelo jogador. Anda nas quatro direções (e nas
## diagonais) lendo as ações do Input Map, sem acelerar na diagonal, e arranha
## com a ação `attack`: golpe de curto alcance na direção em que ele olha, com um
## pequeno intervalo entre os golpes. Sem armas e sem sangue.
##
## Tem 7 corações, contados em meios (`Hearts`). Cada golpe de criatura tira o
## dano dela, deixa o gato invencível por um instante e o empurra para longe dela;
## ao zerar, ele desmaia e emite `fainted`. Recupera automaticamente meio coração
## a cada 5 segundos por padrão. Sofrer dano ou executar um arranhão, mesmo sem
## acertar uma criatura, reinicia a contagem. Não recupera enquanto está desmaiado.

## Emitido a cada arranhão, com a direção do golpe.
signal attacked(direction: Vector2)
## Emitido quando os corações zeram. Quem controla a cena decide o que fazer
## (voltar à cabana).
signal fainted

## Quanto o sprite pisca durante a invencibilidade, em segundos por piscada.
const BLINK_SECONDS := 0.08

## Camada de colisão das criaturas (a 2ª).
const CREATURE_MASK := 2
## Camada de colisão do cenário: paredes e arbustos (a 1ª).
const WORLD_MASK := 1
## Deslocamento do centro do corpo da criatura em relação à origem dela.
const CREATURE_CENTER_OFFSET := Vector2(0, 4)

## Velocidade de caminhada, em pixels por segundo.
@export var speed := 160.0
## Distância do centro do gato até o centro do arranhão, em pixels.
@export var attack_reach := 26.0
## Tamanho da área do arranhão, em pixels.
@export var attack_size := Vector2(36, 36)
## Intervalo mínimo entre dois arranhões, em segundos.
@export var attack_cooldown := 0.4
## Quanto tempo o gato fica invencível depois de levar um golpe, em segundos.
@export var invulnerability_time := 1.0
## Velocidade do empurrão ao levar um golpe, em pixels por segundo.
@export var knockback_speed := 220.0
## Duração do empurrão, em segundos. Durante ele o gato não anda nem arranha.
@export var knockback_seconds := 0.12
## Intervalo sem dano ou arranhões para recuperar vida, em segundos.
## Arranhões no vazio também reiniciam a contagem.
@export var regeneration_interval := 5.0
## Quantidade de meios corações recuperados por intervalo.
@export var regeneration_amount := 1

## Para onde o gato olha: a última direção em que andou (uma das quatro).
var facing := Vector2.DOWN

## Os corações do gato.
var hearts := Hearts.new()

var _cooldown_left := 0.0
var _invulnerable_left := 0.0
var _fainted := false
var _regeneration_elapsed := 0.0
var _knockback_left := 0.0
var _knockback := Vector2.ZERO

@onready var _camera: Camera2D = $Camera
@onready var _scratch: ScratchEffect = $Scratch
@onready var _sprite: Sprite2D = $Sprite


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_invulnerability(delta)
	if _fainted:
		velocity = Vector2.ZERO
		return
	_update_regeneration(delta)
	if _knockback_left > 0.0:
		_knockback_left -= delta
		velocity = _knockback
		move_and_slide()
		return
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	facing = facing_for(direction, facing)
	_sprite.flip_h = flip_for(facing)
	velocity = velocity_for(direction)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack") and not _fainted:
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


## Se o sprite deve ser espelhado. A arte do gato olha para a esquerda, então
## espelha quando ele olha para a direita; para cima e para baixo não espelha.
static func flip_for(direction: Vector2) -> bool:
	return direction.x > 0.0


## Arranha na direção em que o gato olha. Devolve false se ainda estiver no
## intervalo entre golpes. Cada criatura na área do golpe leva um arranhão.
func try_attack() -> bool:
	if _cooldown_left > 0.0 or _fainted or is_knocked_back():
		return false
	_cooldown_left = attack_cooldown
	_regeneration_elapsed = 0.0
	for creature in creatures_in_reach():
		creature.take_scratch(facing)
	_scratch.play(facing)
	attacked.emit(facing)
	return true


## Criaturas dentro da área do golpe agora (a área fica na frente do gato).
## Criatura do outro lado de uma parede ou arbusto não é atingida.
func creatures_in_reach() -> Array[Creature]:
	var hitbox := RectangleShape2D.new()
	hitbox.size = attack_size
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = hitbox
	query.transform = Transform2D(0.0, global_position + facing * attack_reach)
	query.collision_mask = CREATURE_MASK
	query.collide_with_bodies = true
	var found: Array[Creature] = []
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		var creature := hit["collider"] as Creature
		if creature != null and not creature.is_defeated() and _has_clear_path_to(creature):
			found.append(creature)
	return found


## Se não há parede nem arbusto entre o centro do gato e o centro da criatura.
func _has_clear_path_to(creature: Creature) -> bool:
	var target := creature.global_position + CREATURE_CENTER_OFFSET
	var ray := PhysicsRayQueryParameters2D.create(global_position, target, WORLD_MASK, [get_rid()])
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()


## Leva um golpe de criatura: tira `halves` meios corações, deixa o gato invencível
## por `invulnerability_time` e o empurra para longe de `from` (posição de quem
## bateu; sem ela, não há empurrão). Devolve false se o golpe foi ignorado (gato
## invencível ou desmaiado). Ao zerar a vida o gato desmaia.
func take_hit(halves: int = 1, from: Vector2 = Vector2.INF) -> bool:
	if _fainted or is_invulnerable():
		return false
	hearts.hurt(halves)
	if halves > 0:
		_regeneration_elapsed = 0.0
	if hearts.is_empty():
		_fainted = true
		_knockback_left = 0.0
		_set_blink(false)
		fainted.emit()
	else:
		_invulnerable_left = invulnerability_time
		if halves > 0 and from.is_finite():
			_start_knockback(from)
	return true


## Recupera meios corações (até o máximo). Devolve quantos recuperou.
func heal(amount: int = 1) -> int:
	return hearts.heal(amount)


## Recupera vida após um intervalo sem dano ou arranhões.
func _update_regeneration(delta: float) -> void:
	if _fainted or hearts.is_full() or regeneration_interval <= 0.0 or regeneration_amount <= 0:
		_regeneration_elapsed = 0.0
		return

	_regeneration_elapsed += delta

	while _regeneration_elapsed >= regeneration_interval:
		_regeneration_elapsed -= regeneration_interval
		heal(regeneration_amount)

		if hearts.is_full():
			_regeneration_elapsed = 0.0
			return


## Se o gato está sendo empurrado e, por isso, sem controle.
func is_knocked_back() -> bool:
	return _knockback_left > 0.0


## Empurra o gato para longe de `from`. Se estiver exatamente em cima, empurra para
## trás de onde olha.
func _start_knockback(from: Vector2) -> void:
	var away := (global_position - from).normalized()
	if away.is_zero_approx():
		away = -facing
	_knockback = away * knockback_speed
	_knockback_left = knockback_seconds


func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func is_fainted() -> bool:
	return _fainted


func _update_invulnerability(delta: float) -> void:
	if _invulnerable_left <= 0.0:
		return
	_invulnerable_left = maxf(_invulnerable_left - delta, 0.0)
	_set_blink(_invulnerable_left > 0.0 and int(_invulnerable_left / BLINK_SECONDS) % 2 == 0)


## Liga ou desliga a piscada do sprite (mais transparente enquanto "piscando").
func _set_blink(dimmed: bool) -> void:
	_sprite.modulate.a = 0.35 if dimmed else 1.0


## Impede a câmera de mostrar o que está fora da sala (em pixels do mundo).
func set_camera_limits(room: Rect2i) -> void:
	_camera.limit_left = room.position.x
	_camera.limit_top = room.position.y
	_camera.limit_right = room.end.x
	_camera.limit_bottom = room.end.y
