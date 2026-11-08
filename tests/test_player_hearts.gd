extends GutTest
## Confere os corações do Mingau: contato com criatura, invencibilidade, cura e
## desmaio.

const PlayerScene := preload("res://scenes/player/player.tscn")
const CreatureScene := preload("res://scenes/creatures/creature.tscn")

var _player: Player


func before_each() -> void:
	_player = autofree(PlayerScene.instantiate())
	_player.position = Vector2(200, 200)
	add_child(_player)


func test_starts_with_seven_hearts() -> void:
	assert_eq(_player.hearts.current, 7)


func test_a_hit_takes_one_heart_and_makes_the_cat_invulnerable() -> void:
	assert_true(_player.take_hit())
	assert_eq(_player.hearts.current, 6)
	assert_true(_player.is_invulnerable())


func test_hits_during_invulnerability_are_ignored() -> void:
	_player.take_hit()
	assert_false(_player.take_hit())
	assert_eq(_player.hearts.current, 6)


func test_invulnerability_ends_after_its_time() -> void:
	_player.invulnerability_time = 0.2
	_player.take_hit()
	await wait_seconds(0.4)
	assert_false(_player.is_invulnerable())
	assert_eq((_player.get_node("Sprite") as Sprite2D).modulate.a, 1.0)
	assert_true(_player.take_hit())
	assert_eq(_player.hearts.current, 5)


func test_sprite_blinks_while_invulnerable() -> void:
	_player.take_hit()
	await wait_physics_frames(2)
	var seen := {}
	for i in 12:
		seen[(_player.get_node("Sprite") as Sprite2D).modulate.a] = true
		await wait_physics_frames(1)
	assert_gt(seen.size(), 1, "Alterna entre transparente e opaco")


func test_zero_hearts_make_the_cat_faint_once() -> void:
	_player.invulnerability_time = 0.0
	watch_signals(_player)
	for i in 7:
		_player.take_hit()
	assert_true(_player.is_fainted())
	assert_eq(_player.hearts.current, 0)
	assert_signal_emit_count(_player, "fainted", 1)
	assert_false(_player.take_hit(), "Desmaiado, não leva mais golpes")
	assert_signal_emit_count(_player, "fainted", 1)


func test_fainted_cat_does_not_move_or_attack() -> void:
	_player.invulnerability_time = 0.0
	for i in 7:
		_player.take_hit()
	assert_false(_player.try_attack())
	_player.velocity = Vector2.RIGHT * 100
	await wait_physics_frames(2)
	assert_eq(_player.velocity, Vector2.ZERO)


func test_heal_recovers_one_heart_without_passing_seven() -> void:
	_player.take_hit()
	assert_eq(_player.heal(), 1)
	assert_eq(_player.hearts.current, 7)
	assert_eq(_player.heal(), 0)
	assert_eq(_player.hearts.current, 7)


func test_creature_contact_takes_a_heart() -> void:
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = _player.position + Vector2(20, 0)
	add_child(creature)
	await wait_physics_frames(4)
	assert_eq(_player.hearts.current, 6)


func test_creature_contact_repeats_only_after_the_invulnerability() -> void:
	_player.invulnerability_time = 0.3
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = _player.position + Vector2(20, 0)
	add_child(creature)
	await wait_physics_frames(10)
	assert_eq(_player.hearts.current, 6, "Um golpe só durante a invencibilidade")
	await wait_seconds(0.5)
	assert_lt(_player.hearts.current, 6, "Passou a invencibilidade, o contato machuca de novo")


func test_creature_far_away_does_not_hurt() -> void:
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = _player.position + Vector2(80, 0)
	add_child(creature)
	await wait_physics_frames(6)
	assert_eq(_player.hearts.current, 7)


func test_defeated_creature_does_not_hurt() -> void:
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = _player.position + Vector2(60, 0)
	add_child(creature)
	for i in 3:
		creature.take_scratch()
	creature.position = _player.position
	await wait_physics_frames(6)
	assert_eq(_player.hearts.current, 7)


func test_regeneration_waits_for_interval() -> void:
	_player.set_physics_process(false)
	_player.take_hit()
	assert_eq(_player.hearts.current, 6)

	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 6, "Não recupera antes do intervalo")

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 7, "Recupera ao completar o intervalo")


func test_damage_restarts_regeneration_interval() -> void:
	_player.set_physics_process(false)
	_player.invulnerability_time = 0.0
	assert_true(_player.take_hit())

	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 6)

	assert_true(_player.take_hit())
	assert_eq(_player.hearts.current, 5)

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 5, "O novo dano reinicia a espera")

	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 6, "Recupera após dez segundos do novo dano")


func test_scratch_in_empty_space_restarts_regeneration_interval() -> void:
	_player.set_physics_process(false)
	_player.take_hit()

	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 6)

	assert_true(_player.creatures_in_reach().is_empty())
	assert_true(_player.try_attack())

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 6, "Arranhar no vazio reinicia a espera")

	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 7, "Recupera após dez segundos do arranhão")


func test_regeneration_does_not_heal_a_fainted_player() -> void:
	_player.set_physics_process(false)
	assert_true(_player.take_hit(Hearts.MAX))
	assert_true(_player.is_fainted())

	_player._update_regeneration(30.0)
	assert_eq(_player.hearts.current, 0, "Desmaiado, não recupera corações")


func test_regeneration_never_exceeds_maximum_hearts() -> void:
	_player.set_physics_process(false)
	_player.regeneration_amount = 3
	_player.take_hit()

	_player._update_regeneration(10.0)
	assert_eq(_player.hearts.current, Hearts.MAX, "A cura respeita o limite")

	_player._update_regeneration(30.0)
	assert_eq(_player.hearts.current, Hearts.MAX, "Continua no limite")


func test_regeneration_handles_large_delta_and_keeps_remainder() -> void:
	_player.set_physics_process(false)
	_player.regeneration_interval = 2.0
	_player.take_hit(4)
	assert_eq(_player.hearts.current, 3)

	_player._update_regeneration(5.0)
	assert_eq(_player.hearts.current, 5, "Cinco segundos completam dois intervalos")

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 6, "Preserva o segundo restante")
