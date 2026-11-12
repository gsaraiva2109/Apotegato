extends GutTest
## Confere o ataque da criatura: aviso, bote e descanso, a direção travada, o
## arranhão que cancela o bote e o tempo contado só na física.

const CreatureScene := preload("res://scenes/creatures/creature.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")

var _target: Node2D


func before_each() -> void:
	_target = autofree(Node2D.new())
	add_child(_target)


## Grade a partir de linhas de texto: "#" é parede, o resto é livre.
func _grid(rows: Array[String]) -> MazeGrid:
	var grid := MazeGrid.new(rows[0].length(), rows.size())
	for y in rows.size():
		for x in rows[y].length():
			grid.set_blocked(Vector2i(x, y), rows[y][x] == "#")
	return grid


func _creature(grid: MazeGrid, cell: Vector2i) -> Creature:
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = MazeGrid.cell_to_position(cell)
	creature.setup(grid, _target)
	add_child(creature)
	return creature


## Corredor livre para os testes de ataque.
func _corridor() -> MazeGrid:
	return _grid(["###############", "#.............#", "###############"])


## Espera, no máximo `frames` quadros de física, até a criatura chegar ao estado.
func _wait_for_state(creature: Creature, state: CreatureBrain.State, frames: int = 120) -> bool:
	for i in frames:
		if creature.brain.state == state:
			return true
		await wait_physics_frames(1)
	return creature.brain.state == state


func test_combat_numbers_default_to_the_design() -> void:
	var creature := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	assert_eq(creature.damage, 1)
	assert_eq(creature.attack_range, 24.0)
	assert_eq(creature.warning_seconds, 0.4)
	assert_eq(creature.lunge_seconds, 0.12)
	assert_eq(creature.lunge_speed, 160.0)
	assert_eq(creature.rest_seconds, 0.7)
	assert_eq(creature.knockback_speed, 160.0)
	assert_eq(creature.knockback_seconds, 0.12)


func test_there_is_no_permanent_contact_area_only_the_strike_area() -> void:
	var creature := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	assert_null(creature.get_node_or_null("ContactArea"))
	assert_not_null(creature.get_node("StrikeArea"))


func test_setup_with_catalog_data_sets_damage_hits_and_speed() -> void:
	var data := CreatureCatalog.Entry.new()
	data.id = "forte"
	data.damage = 2
	data.hits = 4
	data.speed = 80.0
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.setup(_grid(["###", "#.#", "###"]), _target, data)
	add_child(creature)
	assert_eq(creature.creature_id, "forte")
	assert_eq(creature.damage, 2)
	assert_eq(creature.speed, 80.0)
	for i in 3:
		creature.take_scratch()
	assert_false(creature.is_defeated(), "A forte aguenta 4 arranhões")
	creature.take_scratch()
	assert_true(creature.is_defeated())


func test_strong_creature_is_bigger_and_darker_for_now() -> void:
	var data := CreatureCatalog.Entry.new()
	data.damage = 2
	data.hits = 4
	data.speed = 80.0
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.setup(_grid(["###", "#.#", "###"]), _target, data)
	add_child(creature)
	var sprite: Sprite2D = creature.get_node("Sprite")
	assert_eq(sprite.scale, Vector2.ONE * Creature.STRONG_SCALE)
	assert_lt(sprite.modulate.r, 1.0)
	var weak := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	assert_eq((weak.get_node("Sprite") as Sprite2D).scale, Vector2.ONE)
	assert_eq((weak.get_node("Sprite") as Sprite2D).modulate, Color.WHITE)


func test_stops_and_warns_when_the_player_is_in_range() -> void:
	var creature := _creature(_corridor(), Vector2i(1, 1))
	_target.position = creature.position + Vector2(20, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.WARNING))
	var stopped_at := creature.position
	await wait_physics_frames(5)
	assert_eq(creature.position, stopped_at, "Parada durante o aviso")


func test_warning_blinks_red_and_hops() -> void:
	var creature := _creature(_corridor(), Vector2i(1, 1))
	_target.position = creature.position + Vector2(20, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.WARNING))
	var sprite: Sprite2D = creature.get_node("Sprite")
	var reddest := 1.0
	var highest := 0.0
	for i in 20:
		await wait_physics_frames(1)
		reddest = minf(reddest, sprite.modulate.g)
		highest = maxf(highest, -sprite.position.y)
	assert_lt(reddest, 0.7, "Pisca em vermelho")
	assert_gt(highest, 1.0, "Dá um pulinho")
	assert_true(await _wait_for_state(creature, CreatureBrain.State.LUNGE))
	assert_eq(sprite.modulate, Color.WHITE, "Acabou o aviso, volta ao normal")
	assert_eq(sprite.position, Vector2.ZERO)


func test_lunge_moves_toward_the_locked_direction_even_if_the_player_moves() -> void:
	var creature := _creature(_corridor(), Vector2i(1, 1))
	_target.position = creature.position + Vector2(20, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.WARNING))
	_target.position = creature.position + Vector2(-20, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.LUNGE))
	var start := creature.position
	await wait_seconds(0.1)
	assert_gt(creature.position.x, start.x + 8.0, "Foi para a direção travada")


func test_lunge_then_rest_then_warns_again_while_the_player_stays_close() -> void:
	var creature := _creature(_corridor(), Vector2i(1, 1))
	_target.position = creature.position + Vector2(20, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.LUNGE))
	assert_true(await _wait_for_state(creature, CreatureBrain.State.REST))
	var resting_at := creature.position
	await wait_physics_frames(10)
	assert_eq(creature.position, resting_at, "Descansa parada")
	assert_true(await _wait_for_state(creature, CreatureBrain.State.WARNING, 90))


func test_scratch_during_the_warning_cancels_the_lunge_and_nobody_gets_hurt() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	player.position = MazeGrid.cell_to_position(Vector2i(5, 1))
	add_child(player)
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = player.position + Vector2(-20, 0)
	creature.setup(_corridor(), player)
	add_child(creature)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.WARNING))
	creature.take_scratch(Vector2.LEFT)
	assert_eq(creature.brain.state, CreatureBrain.State.REST)
	await wait_seconds(0.5)
	assert_ne(creature.brain.state, CreatureBrain.State.LUNGE)
	assert_eq(player.hearts.current, Hearts.MAX, "O bote foi cancelado")


func test_creature_does_not_warn_a_fainted_player() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	player.position = MazeGrid.cell_to_position(Vector2i(5, 1))
	add_child(player)
	player.take_hit(Hearts.MAX)
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = player.position + Vector2(-20, 0)
	creature.setup(_corridor(), player)
	add_child(creature)
	await wait_seconds(0.8)
	assert_false(creature.brain.is_attacking())
	assert_eq(creature.brain.state, CreatureBrain.State.UNAWARE)


func test_combat_never_pauses_the_tree_nor_uses_timers() -> void:
	# O tempo do combate conta no _physics_process: nada de Timer nem de pausa,
	# para congelar junto com a máquina de estados do jogo.
	for path in [
		"res://scenes/creatures/creature.gd",
		"res://scenes/player/player.gd",
		"res://scripts/creature_brain.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		assert_false(source.contains("paused"), "%s mexe na pausa" % path)
		assert_false(source.contains("create_timer"), "%s usa create_timer" % path)
		assert_false(source.contains("Timer.new"), "%s usa Timer" % path)
		assert_false(source.contains("PROCESS_MODE_ALWAYS"), "%s roda durante a pausa" % path)
