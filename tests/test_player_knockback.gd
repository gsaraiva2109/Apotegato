extends GutTest
## Confere o empurrão do Mingau ao levar um golpe e o golpe das criaturas: só o
## bote machuca, e o gato desmaiado não é atacado.

const PlayerScene := preload("res://scenes/player/player.tscn")
const CreatureScene := preload("res://scenes/creatures/creature.tscn")

var _player: Player


func before_each() -> void:
	_player = autofree(PlayerScene.instantiate())
	_player.position = Vector2(200, 200)
	add_child(_player)


## Grade toda livre, grande o bastante para a criatura andar.
func _open_grid() -> MazeGrid:
	return MazeGrid.new(20, 10)


## Criatura que persegue o gato, a `offset` pixels dele.
func _creature_at(offset: Vector2, damage: int = 1) -> Creature:
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = _player.position + offset
	creature.damage = damage
	creature.setup(_open_grid(), _player)
	add_child(creature)
	return creature


func test_hit_pushes_the_cat_away_from_the_attacker() -> void:
	_player.take_hit(1, _player.global_position + Vector2(-30, 0))
	assert_true(_player.is_knocked_back())
	var start := _player.position
	await wait_physics_frames(3)
	assert_gt(_player.position.x, start.x, "Foi para a direita, longe de quem bateu")
	assert_almost_eq(_player.position.y, start.y, 0.01)


func test_knockback_speed_and_time_match_the_design() -> void:
	assert_eq(_player.knockback_speed, 220.0)
	assert_eq(_player.knockback_seconds, 0.12)


func test_knockback_moves_about_26_pixels_and_then_stops() -> void:
	var start := _player.position
	_player.take_hit(1, _player.global_position + Vector2(0, -30))
	await wait_seconds(0.4)
	assert_false(_player.is_knocked_back())
	assert_almost_eq(_player.position.y - start.y, 26.4, 6.0)
	assert_eq(_player.velocity, Vector2.ZERO, "Sem entrada, para quando o empurrão acaba")


func test_cat_has_no_control_while_knocked_back() -> void:
	_player.take_hit(1, _player.global_position + Vector2(-30, 0))
	Input.action_press("move_left")
	var start := _player.position
	await wait_physics_frames(2)
	Input.action_release("move_left")
	assert_gt(_player.position.x, start.x, "O empurrão vence o comando")
	assert_false(_player.try_attack(), "Também não arranha durante o empurrão")


func test_hit_without_a_source_does_not_push() -> void:
	_player.take_hit(1)
	assert_false(_player.is_knocked_back())


func test_the_hit_that_makes_the_cat_faint_does_not_push() -> void:
	_player.invulnerability_time = 0.0
	_player.take_hit(13)
	_player.take_hit(1, _player.global_position + Vector2(-30, 0))
	assert_true(_player.is_fainted())
	assert_false(_player.is_knocked_back())


func test_attack_reach_and_size_are_exports() -> void:
	assert_eq(_player.attack_reach, 26.0)
	assert_eq(_player.attack_size, Vector2(36, 36))


func test_touching_a_creature_does_not_hurt() -> void:
	var creature := _creature_at(Vector2(20, 0))
	creature.brain.state = CreatureBrain.State.REST
	await wait_physics_frames(10)
	assert_eq(_player.hearts.current, 14)


func test_creature_lunge_takes_its_damage_and_pushes_the_cat() -> void:
	_creature_at(Vector2(20, 0), 1)
	await wait_seconds(1.2)
	assert_eq(_player.hearts.current, 13, "Meio coração do bote")
	assert_lt(_player.position.x, 190.0, "Foi empurrado para longe da criatura")


func test_strong_creature_takes_a_whole_heart() -> void:
	_creature_at(Vector2(20, 0), 2)
	await wait_seconds(1.2)
	assert_eq(_player.hearts.current, 12)


func test_creature_does_not_hurt_during_the_warning() -> void:
	_creature_at(Vector2(20, 0))
	await wait_seconds(0.25)
	assert_eq(_player.hearts.current, 14, "Ainda no aviso")


func test_creature_far_away_does_not_hurt() -> void:
	_creature_at(Vector2(200, 0))
	await wait_seconds(0.3)
	assert_eq(_player.hearts.current, 14)


func test_creature_does_not_attack_a_fainted_cat() -> void:
	_player.take_hit(Hearts.MAX)
	var creature := _creature_at(Vector2(20, 0))
	await wait_seconds(1.0)
	assert_eq(_player.hearts.current, 0)
	assert_false(creature.brain.is_attacking())


func test_defeated_creature_does_not_hurt() -> void:
	var creature := _creature_at(Vector2(60, 0))
	for i in 3:
		creature.take_scratch()
	creature.position = _player.position
	await wait_seconds(1.0)
	assert_eq(_player.hearts.current, 14)
