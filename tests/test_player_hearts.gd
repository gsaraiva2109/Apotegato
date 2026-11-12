extends GutTest
## Confere a vida do Mingau em meios corações: dano, invencibilidade, empurrão,
## cura, desmaio e o golpe das criaturas (só o bote machuca).

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


func test_starts_with_fourteen_halves() -> void:
	assert_eq(_player.hearts.current, 14)


func test_a_half_heart_hit_takes_one_half_and_makes_the_cat_invulnerable() -> void:
	assert_true(_player.take_hit(1))
	assert_eq(_player.hearts.current, 13)
	assert_true(_player.is_invulnerable())


func test_a_whole_heart_hit_takes_two_halves() -> void:
	assert_true(_player.take_hit(2))
	assert_eq(_player.hearts.current, 12)


func test_hits_during_invulnerability_are_ignored() -> void:
	_player.take_hit(2)
	assert_false(_player.take_hit(2))
	assert_eq(_player.hearts.current, 12)


func test_invulnerability_blinks_by_default() -> void:
	_player.invulnerability_time = 1.0
	_player.take_hit(1)
	var alphas := {}
	for i in 12:
		_player._update_invulnerability(Player.BLINK_SECONDS)
		alphas[_player.get_node("Sprite").modulate.a] = true
	assert_gt(alphas.size(), 1, "Alterna entre transparente e opaco")


func test_invulnerability_is_steady_with_reduced_effects() -> void:
	AudioSettings.reduce_effects = true
	_player.invulnerability_time = 1.0
	_player.take_hit(1)
	var alphas := {}
	for i in 12:
		_player._update_invulnerability(Player.BLINK_SECONDS)
		alphas[_player.get_node("Sprite").modulate.a] = true
	AudioSettings.reduce_effects = false
	assert_eq(alphas.size(), 1, "Sem piscar")
	assert_almost_eq(alphas.keys()[0], Player.REDUCED_DIM_ALPHA, 0.001)


func test_invulnerability_lasts_one_second_by_default() -> void:
	assert_eq(_player.invulnerability_time, 1.0)


func test_invulnerability_ends_after_its_time() -> void:
	_player.invulnerability_time = 0.2
	_player.take_hit(1)
	await wait_seconds(0.4)
	assert_false(_player.is_invulnerable())
	assert_eq((_player.get_node("Sprite") as Sprite2D).modulate.a, 1.0)
	assert_true(_player.take_hit(1))
	assert_eq(_player.hearts.current, 12)


func test_sprite_blinks_while_invulnerable() -> void:
	_player.take_hit(1)
	await wait_physics_frames(2)
	var seen := {}
	for i in 12:
		seen[(_player.get_node("Sprite") as Sprite2D).modulate.a] = true
		await wait_physics_frames(1)
	assert_gt(seen.size(), 1, "Alterna entre transparente e opaco")


func test_zero_hearts_make_the_cat_faint_once() -> void:
	_player.invulnerability_time = 0.0
	watch_signals(_player)
	for i in 14:
		_player.take_hit(1)
	assert_true(_player.is_fainted())
	assert_eq(_player.hearts.current, 0)
	assert_signal_emit_count(_player, "fainted", 1)
	assert_false(_player.take_hit(1), "Desmaiado, não leva mais golpes")
	assert_signal_emit_count(_player, "fainted", 1)


func test_the_last_half_heart_makes_the_cat_faint() -> void:
	_player.invulnerability_time = 0.0
	_player.take_hit(13)
	assert_false(_player.is_fainted())
	assert_eq(_player.hearts.current, 1)
	_player.take_hit(1)
	assert_true(_player.is_fainted())


func test_a_whole_heart_hit_with_half_a_heart_left_faints() -> void:
	_player.invulnerability_time = 0.0
	_player.take_hit(13)
	_player.take_hit(2)
	assert_eq(_player.hearts.current, 0, "Não passa de zero")
	assert_true(_player.is_fainted())


func test_fainted_cat_does_not_move_or_attack() -> void:
	_player.take_hit(Hearts.MAX)
	assert_false(_player.try_attack())
	_player.velocity = Vector2.RIGHT * 100
	await wait_physics_frames(2)
	assert_eq(_player.velocity, Vector2.ZERO)


func test_heal_recovers_halves_without_passing_the_maximum() -> void:
	_player.take_hit(2)
	assert_eq(_player.heal(1), 1)
	assert_eq(_player.hearts.current, 13)
	assert_eq(_player.heal(2), 1, "Só coube o meio que faltava")
	assert_eq(_player.hearts.current, 14)
	assert_eq(_player.heal(2), 0)


func test_scratch_hits_a_creature_inside_the_reach_only() -> void:
	var creature := _creature_at(Vector2(28, 0))
	creature.set_physics_process(false)
	_player.facing = Vector2.RIGHT
	await wait_physics_frames(2)
	assert_eq(_player.creatures_in_reach().size(), 1)
	_player.attack_reach = 100.0
	assert_true(_player.creatures_in_reach().is_empty(), "O alcance é configurável")
