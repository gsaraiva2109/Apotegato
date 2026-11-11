extends GutTest
## Confere o arranhão do gato: direção, alcance, intervalo entre golpes, três
## golpes para derrotar e o efeito visual.

const PlayerScene := preload("res://scenes/player/player.tscn")
const CreatureScene := preload("res://scenes/creatures/creature.tscn")

var _player: Player


func before_each() -> void:
	_player = autofree(PlayerScene.instantiate())
	_player.position = Vector2(200, 200)
	add_child(_player)


func _creature_at(offset: Vector2) -> Creature:
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = _player.position + offset
	add_child(creature)
	return creature


func test_facing_follows_the_last_direction() -> void:
	assert_eq(Player.facing_for(Vector2.LEFT, Vector2.DOWN), Vector2.LEFT)
	assert_eq(Player.facing_for(Vector2(0.2, -1), Vector2.DOWN), Vector2.UP)
	assert_eq(
		Player.facing_for(Vector2(1, 1), Vector2.DOWN), Vector2.RIGHT, "Na diagonal, horizontal"
	)
	assert_eq(Player.facing_for(Vector2.ZERO, Vector2.LEFT), Vector2.LEFT, "Parado, mantém")


func test_sprite_flips_only_when_facing_right() -> void:
	assert_true(Player.flip_for(Vector2.RIGHT))
	assert_false(Player.flip_for(Vector2.LEFT), "A arte do gato já olha para a esquerda")
	assert_false(Player.flip_for(Vector2.UP))
	assert_false(Player.flip_for(Vector2.DOWN))


func test_starts_facing_down() -> void:
	assert_eq(_player.facing, Vector2.DOWN)


func test_attack_hits_a_creature_in_front() -> void:
	_player.facing = Vector2.RIGHT
	var creature := _creature_at(Vector2(28, 0))
	await wait_physics_frames(2)
	assert_eq(_player.creatures_in_reach(), [creature])
	assert_true(_player.try_attack())
	assert_eq(creature.hits_to_defeat - 1, 2)
	assert_false(creature.is_defeated())


func _wall_at(offset: Vector2) -> StaticBody2D:
	var wall: StaticBody2D = autofree(StaticBody2D.new())
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(32, 32)
	shape.shape = rect
	wall.add_child(shape)
	wall.position = _player.position + offset
	add_child(wall)
	return wall


func test_attack_does_not_pass_through_a_wall() -> void:
	_player.facing = Vector2.RIGHT
	var creature := _creature_at(Vector2(40, 0))
	_wall_at(Vector2(20, 0))
	await wait_physics_frames(2)
	assert_true(_player.creatures_in_reach().is_empty(), "A parede protege a criatura")
	_player.attack_cooldown = 0.0
	for i in creature.hits_to_defeat:
		assert_true(_player.try_attack())
	assert_false(creature.is_defeated(), "Nenhum arranhão atravessou a parede")


func test_attack_hits_when_the_wall_is_not_in_the_way() -> void:
	_player.facing = Vector2.RIGHT
	var creature := _creature_at(Vector2(28, 0))
	_wall_at(Vector2(0, 40))
	await wait_physics_frames(2)
	assert_eq(_player.creatures_in_reach(), [creature])


func test_attack_misses_creatures_behind_or_far() -> void:
	_player.facing = Vector2.RIGHT
	_creature_at(Vector2(-28, 0))
	_creature_at(Vector2(0, 28))
	_creature_at(Vector2(90, 0))
	await wait_physics_frames(2)
	assert_true(_player.creatures_in_reach().is_empty())


func test_attack_follows_the_facing_direction() -> void:
	var above := _creature_at(Vector2(0, -28))
	await wait_physics_frames(2)
	_player.facing = Vector2.DOWN
	assert_true(_player.creatures_in_reach().is_empty())
	_player.facing = Vector2.UP
	assert_eq(_player.creatures_in_reach(), [above])


func test_there_is_an_interval_between_scratches() -> void:
	watch_signals(_player)
	assert_true(_player.try_attack())
	assert_false(_player.try_attack(), "Ainda no intervalo")
	assert_signal_emit_count(_player, "attacked", 1)
	await wait_seconds(_player.attack_cooldown + 0.1)
	assert_true(_player.try_attack())
	assert_signal_emit_count(_player, "attacked", 2)


func test_third_scratch_defeats_the_creature() -> void:
	_player.facing = Vector2.RIGHT
	_player.attack_cooldown = 0.0
	var creature := _creature_at(Vector2(28, 0))
	watch_signals(creature)
	for i in 3:
		creature.position = _player.position + Vector2(28, 0)
		await wait_physics_frames(2)
		assert_false(creature.is_defeated(), "Ainda viva antes do golpe %d" % (i + 1))
		assert_true(_player.try_attack())
	assert_true(creature.is_defeated())
	assert_signal_emit_count(creature, "defeated", 1)


func test_scratch_effect_shows_and_fades() -> void:
	var effect: ScratchEffect = _player.get_node("Scratch")
	assert_false(effect.visible)
	_player.facing = Vector2.LEFT
	_player.try_attack()
	assert_true(effect.visible)
	assert_true(effect.is_playing())
	await wait_seconds(ScratchEffect.DURATION + 0.1)
	assert_false(effect.visible)


func test_attack_action_triggers_the_scratch() -> void:
	watch_signals(_player)
	var event := InputEventAction.new()
	event.action = "attack"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_signal_emitted(_player, "attacked")
