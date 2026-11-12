extends GutTest
## Confere a máquina de estados do jogo (GameFlow) e a pausa que o GameState
## aplica fora da exploração.

const PlayerScene := preload("res://scenes/player/player.tscn")
const CreatureScene := preload("res://scenes/creatures/creature.tscn")

var _flow: GameFlow


func before_each() -> void:
	_flow = GameFlow.new()


func after_each() -> void:
	GameState.flow.reset()
	get_tree().paused = false


func test_starts_exploring_and_lets_the_player_act() -> void:
	assert_eq(_flow.state, GameFlow.State.EXPLORATION)
	assert_true(_flow.can_player_act())
	assert_false(_flow.is_frozen())


func test_allowed_transitions_change_the_state_and_emit() -> void:
	var allowed := [
		[GameFlow.State.EXPLORATION, GameFlow.State.DIALOGUE],
		[GameFlow.State.DIALOGUE, GameFlow.State.EXPLORATION],
		[GameFlow.State.EXPLORATION, GameFlow.State.DELIVERY],
		[GameFlow.State.DELIVERY, GameFlow.State.DIALOGUE],
		[GameFlow.State.DIALOGUE, GameFlow.State.DELIVERY],
		[GameFlow.State.DELIVERY, GameFlow.State.EXPLORATION],
		[GameFlow.State.EXPLORATION, GameFlow.State.MENU],
		[GameFlow.State.MENU, GameFlow.State.EXPLORATION],
		[GameFlow.State.EXPLORATION, GameFlow.State.DIALOGUE],
		[GameFlow.State.DIALOGUE, GameFlow.State.COMPLETION],
	]
	watch_signals(_flow)
	for step: Array in allowed:
		assert_eq(_flow.state, step[0])
		assert_true(_flow.request(step[1]), "%s -> %s" % step)
		assert_eq(_flow.state, step[1])
		assert_signal_emitted_with_parameters(_flow, "state_changed", step)


func test_forbidden_transitions_are_refused() -> void:
	var forbidden := {
		GameFlow.State.EXPLORATION: [GameFlow.State.COMPLETION],
		GameFlow.State.MENU:
		[GameFlow.State.DIALOGUE, GameFlow.State.DELIVERY, GameFlow.State.COMPLETION],
		GameFlow.State.DELIVERY: [GameFlow.State.MENU, GameFlow.State.COMPLETION],
		GameFlow.State.DIALOGUE: [GameFlow.State.MENU],
		GameFlow.State.COMPLETION:
		[
			GameFlow.State.EXPLORATION,
			GameFlow.State.DIALOGUE,
			GameFlow.State.DELIVERY,
			GameFlow.State.MENU
		],
	}
	for from: GameFlow.State in forbidden:
		for to: GameFlow.State in forbidden[from]:
			var flow := GameFlow.new()
			flow.state = from
			watch_signals(flow)
			assert_false(flow.request(to), "%d -> %d deveria ser recusada" % [from, to])
			assert_eq(flow.state, from)
			assert_signal_not_emitted(flow, "state_changed")


func test_every_state_has_a_rule_and_a_name() -> void:
	for state: GameFlow.State in GameFlow.State.values():
		assert_true(GameFlow.TRANSITIONS.has(state))
		assert_true(GameFlow.STATE_NAMES.has(state))


func test_requesting_the_current_state_does_nothing() -> void:
	watch_signals(_flow)
	assert_false(_flow.request(GameFlow.State.EXPLORATION))
	assert_signal_not_emitted(_flow, "state_changed")


func test_only_exploration_lets_the_player_act() -> void:
	for state: GameFlow.State in GameFlow.State.values():
		_flow.state = state
		assert_eq(_flow.can_player_act(), state == GameFlow.State.EXPLORATION)
		assert_eq(_flow.is_frozen(), state != GameFlow.State.EXPLORATION)


func test_menus_open_only_from_exploration_and_close_back_to_it() -> void:
	assert_true(_flow.open_menu())
	assert_false(_flow.open_menu(), "Um menu de cada vez")
	assert_true(_flow.close_menu())
	assert_eq(_flow.state, GameFlow.State.EXPLORATION)
	assert_false(_flow.close_menu(), "Sem menu aberto, não faz nada")
	_flow.request(GameFlow.State.DIALOGUE)
	assert_false(_flow.open_menu(), "Não abre menu no meio de um diálogo")
	assert_false(_flow.close_menu())
	assert_eq(_flow.state, GameFlow.State.DIALOGUE)


func test_reset_returns_to_exploration_from_any_state() -> void:
	_flow.request(GameFlow.State.DIALOGUE)
	_flow.request(GameFlow.State.COMPLETION)
	_flow.reset()
	assert_eq(_flow.state, GameFlow.State.EXPLORATION)


func test_game_state_freezes_the_game_outside_exploration() -> void:
	GameState.flow.request(GameFlow.State.DIALOGUE)
	assert_true(get_tree().paused)
	GameState.flow.request(GameFlow.State.EXPLORATION)
	assert_false(get_tree().paused)
	GameState.flow.open_menu()
	assert_true(get_tree().paused)
	GameState.new_game()
	assert_eq(GameState.flow.state, GameFlow.State.EXPLORATION)
	assert_false(get_tree().paused, "Campanha nova começa explorando")


func test_cat_and_creatures_stop_while_frozen() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	add_child(player)
	var creature: Creature = autofree(CreatureScene.instantiate())
	add_child(creature)
	assert_true(player.can_process())
	assert_true(creature.can_process())
	for state: GameFlow.State in [
		GameFlow.State.DIALOGUE, GameFlow.State.DELIVERY, GameFlow.State.MENU
	]:
		GameState.flow.reset()
		GameState.flow.request(state)
		assert_false(player.can_process(), "O gato para em %s" % GameFlow.STATE_NAMES[state])
		assert_false(creature.can_process(), "A criatura para em %s" % GameFlow.STATE_NAMES[state])
	GameState.flow.reset()
	assert_true(player.can_process())
	assert_true(creature.can_process())
