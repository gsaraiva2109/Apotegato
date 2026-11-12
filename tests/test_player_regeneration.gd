extends GutTest
## Confere configurações e casos de borda da recuperação automática de vida.

const PlayerScene := preload("res://scenes/player/player.tscn")

var _player: Player


func before_each() -> void:
	_player = autofree(PlayerScene.instantiate())
	_player.position = Vector2(200, 200)
	add_child(_player)
	_player.set_physics_process(false)


func test_nonpositive_interval_disables_regeneration() -> void:
	_player.take_hit()
	for interval in [0.0, -1.0]:
		_player.regeneration_interval = interval
		_player._update_regeneration(20.0)
		assert_eq(_player.hearts.current, 13, "Intervalo não positivo desativa a recuperação")
	_player.regeneration_interval = 5.0
	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 13, "Não acumula tempo enquanto está desativada")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 14)


func test_nonpositive_amount_disables_regeneration() -> void:
	_player.take_hit()
	for amount in [0, -1]:
		_player.regeneration_amount = amount
		_player._update_regeneration(20.0)
		assert_eq(_player.hearts.current, 13, "Quantidade não positiva desativa a recuperação")
	_player.regeneration_amount = 1
	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 13, "Não acumula tempo enquanto está desativada")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 14)


func test_regeneration_uses_configured_amount() -> void:
	_player.regeneration_amount = 2
	_player.take_hit(4)
	_player._update_regeneration(5.0)
	assert_eq(_player.hearts.current, 12, "Recupera a quantidade configurada")


func test_zero_damage_does_not_restart_regeneration() -> void:
	_player.invulnerability_time = 0.0
	_player.take_hit(2)
	_player._update_regeneration(4.0)
	assert_true(_player.take_hit(0))
	assert_eq(_player.hearts.current, 12, "Dano zero não remove vida")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 13, "Dano zero não reinicia a espera")


func test_ignored_hit_does_not_restart_regeneration() -> void:
	_player.invulnerability_time = 20.0
	_player.take_hit(2)
	_player._update_regeneration(4.0)
	assert_false(_player.take_hit(), "Golpe ignorado durante a invencibilidade")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 13, "Golpe ignorado não reinicia a espera")


func test_rejected_attack_does_not_restart_regeneration() -> void:
	_player.take_hit(2)
	assert_true(_player.try_attack())
	_player._update_regeneration(4.0)
	assert_false(_player.try_attack(), "O cooldown ainda está ativo neste teste")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 13, "Tentativa rejeitada não reinicia a espera")


func test_physics_updates_regeneration_without_blocking_movement() -> void:
	var initial_position := _player.position
	Input.action_press("move_right")

	_player._physics_process(1.0 / 60.0)
	var moved_with_full_health := _player.position.x > initial_position.x

	_player.regeneration_interval = 0.1
	_player.take_hit()
	_player._physics_process(0.1)
	var recovered_hearts := _player.hearts.current

	_player.regeneration_interval = 0.0
	var position_before_disabled := _player.position
	_player._physics_process(1.0 / 60.0)
	var moved_with_disabled_interval := _player.position.x > position_before_disabled.x

	_player.regeneration_interval = 5.0
	_player.regeneration_amount = 0
	var position_before_zero_amount := _player.position
	_player._physics_process(1.0 / 60.0)
	var moved_with_zero_amount := _player.position.x > position_before_zero_amount.x

	Input.action_release("move_right")

	assert_true(moved_with_full_health, "Vida cheia não bloqueia o movimento")
	assert_eq(recovered_hearts, Hearts.MAX, "A física atualiza a recuperação")
	assert_true(moved_with_disabled_interval, "Intervalo zero não bloqueia o movimento")
	assert_true(moved_with_zero_amount, "Quantidade zero não bloqueia o movimento")


func test_regeneration_default_is_half_a_heart_every_five_seconds() -> void:
	assert_eq(_player.regeneration_interval, 5.0)
	assert_eq(_player.regeneration_amount, 1)


func test_regeneration_waits_for_interval() -> void:
	_player.set_physics_process(false)
	_player.take_hit(2)
	assert_eq(_player.hearts.current, 12)

	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 12, "Não recupera antes do intervalo")

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 13, "Recupera meio coração ao completar o intervalo")

	_player._update_regeneration(5.0)
	assert_eq(_player.hearts.current, 14)


func test_damage_restarts_regeneration_interval() -> void:
	_player.set_physics_process(false)
	_player.invulnerability_time = 0.0
	assert_true(_player.take_hit(2))

	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 12)

	assert_true(_player.take_hit(2))
	assert_eq(_player.hearts.current, 10)

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 10, "O novo dano reinicia a espera")

	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 11, "Recupera 5 segundos depois do novo dano")


func test_scratch_in_empty_space_restarts_regeneration_interval() -> void:
	_player.set_physics_process(false)
	_player.take_hit(2)

	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 12)

	assert_true(_player.creatures_in_reach().is_empty())
	assert_true(_player.try_attack())

	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 12, "Arranhar no vazio reinicia a espera")

	_player._update_regeneration(4.0)
	assert_eq(_player.hearts.current, 13, "Recupera 5 segundos depois do arranhão")
