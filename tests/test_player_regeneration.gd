extends GutTest
## Confere configurações e casos de borda da recuperação automática de corações.

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
		assert_eq(_player.hearts.current, 6, "Intervalo não positivo desativa a recuperação")
	_player.regeneration_interval = 10.0
	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 6, "Não acumula tempo enquanto está desativada")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 7)


func test_nonpositive_amount_disables_regeneration() -> void:
	_player.take_hit()
	for amount in [0, -1]:
		_player.regeneration_amount = amount
		_player._update_regeneration(20.0)
		assert_eq(_player.hearts.current, 6, "Quantidade não positiva desativa a recuperação")
	_player.regeneration_amount = 1
	_player._update_regeneration(9.0)
	assert_eq(_player.hearts.current, 6, "Não acumula tempo enquanto está desativada")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 7)


func test_regeneration_uses_configured_amount() -> void:
	_player.regeneration_amount = 2
	_player.take_hit(4)
	_player._update_regeneration(10.0)
	assert_eq(_player.hearts.current, 5, "Recupera a quantidade configurada")


func test_zero_damage_does_not_restart_regeneration() -> void:
	_player.invulnerability_time = 0.0
	_player.take_hit(2)
	_player._update_regeneration(9.0)
	assert_true(_player.take_hit(0))
	assert_eq(_player.hearts.current, 5, "Dano zero não remove corações")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 6, "Dano zero não reinicia a espera")


func test_ignored_hit_does_not_restart_regeneration() -> void:
	_player.invulnerability_time = 20.0
	_player.take_hit(2)
	_player._update_regeneration(9.0)
	assert_false(_player.take_hit(), "Golpe ignorado durante a invencibilidade")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 6, "Golpe ignorado não reinicia a espera")


func test_rejected_attack_does_not_restart_regeneration() -> void:
	_player.take_hit(2)
	assert_true(_player.try_attack())
	_player._update_regeneration(9.0)
	assert_false(_player.try_attack(), "O cooldown ainda está ativo neste teste")
	_player._update_regeneration(1.0)
	assert_eq(_player.hearts.current, 6, "Tentativa rejeitada não reinicia a espera")
