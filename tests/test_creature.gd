extends GutTest
## Confere a criatura: fica parada, persegue quando o gato chega perto, respeita
## as paredes do labirinto, desiste quando ele se afasta e cai com três
## arranhões, sem sangue.

const CreatureScene := preload("res://scenes/creatures/creature.tscn")

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


func test_default_distances_and_hits() -> void:
	var creature := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	assert_eq(creature.hits_to_defeat, 3)
	assert_gt(creature.give_up_distance, creature.detection_distance)
	assert_eq(creature.collision_layer, 2)


func test_stays_still_when_the_player_is_far() -> void:
	var grid := _grid(["#############", "#...........#", "#############"])
	var creature := _creature(grid, Vector2i(1, 1))
	_target.position = MazeGrid.cell_to_position(Vector2i(11, 1))
	var start := creature.position
	await wait_physics_frames(20)
	assert_false(creature.brain.is_chasing())
	assert_eq(creature.position, start)


func test_chases_when_the_player_comes_close() -> void:
	var grid := _grid(["#############", "#...........#", "#############"])
	var creature := _creature(grid, Vector2i(1, 1))
	_target.position = MazeGrid.cell_to_position(Vector2i(5, 1))
	var start := creature.position
	await wait_physics_frames(30)
	assert_true(creature.brain.is_chasing())
	assert_gt(creature.position.x, start.x + 10.0, "Andou em direção ao gato")


func test_detection_distance_is_configurable() -> void:
	var grid := _grid(["#############", "#...........#", "#############"])
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.detection_distance = 32.0
	creature.give_up_distance = 64.0
	creature.position = MazeGrid.cell_to_position(Vector2i(1, 1))
	creature.setup(grid, _target)
	add_child(creature)
	_target.position = MazeGrid.cell_to_position(Vector2i(5, 1))
	await wait_physics_frames(20)
	assert_false(creature.brain.is_chasing(), "4 tiles está além dos 32 px configurados")


func test_a_wall_in_between_hides_the_player() -> void:
	# O gato está a 2 tiles em linha reta, mas do outro lado de uma parede inteira.
	var grid := _grid(["#########", "#..#....#", "#..#....#", "#..#....#", "#########"])
	var creature := _creature(grid, Vector2i(2, 2))
	_target.position = MazeGrid.cell_to_position(Vector2i(4, 2))
	var start := creature.position
	await wait_physics_frames(30)
	assert_false(creature.brain.is_chasing())
	assert_eq(creature.position, start)


func test_chase_goes_around_the_wall_never_through_it() -> void:
	var grid := _grid(["#########", "#..#....#", "#..#....#", "#.......#", "#########"])
	var creature := _creature(grid, Vector2i(2, 2))
	_target.position = MazeGrid.cell_to_position(Vector2i(4, 2))
	var visited := {}
	for i in 90:
		await wait_physics_frames(1)
		visited[MazeGrid.position_to_cell(creature.position)] = true
	assert_true(creature.brain.is_chasing())
	for cell: Vector2i in visited:
		assert_true(grid.is_free(cell), "Passou pela parede em %s" % cell)
	assert_lt(creature.position.distance_to(_target.position), 40.0, "Chegou perto do gato")


func test_gives_up_when_the_player_runs_away() -> void:
	var grid := _grid(["###############", "#.............#", "###############"])
	var creature := _creature(grid, Vector2i(2, 1))
	_target.position = MazeGrid.cell_to_position(Vector2i(4, 1))
	await wait_physics_frames(20)
	assert_true(creature.brain.is_chasing())
	_target.position = MazeGrid.cell_to_position(Vector2i(13, 1))
	await wait_physics_frames(30)
	assert_false(creature.brain.is_chasing(), "O gato despistou a criatura")
	var stopped_at := creature.position
	await wait_physics_frames(10)
	assert_eq(creature.position, stopped_at, "Parou de andar")


func test_three_scratches_defeat_it() -> void:
	var creature := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	watch_signals(creature)
	creature.take_scratch(Vector2.RIGHT)
	creature.take_scratch(Vector2.RIGHT)
	assert_false(creature.is_defeated())
	assert_signal_not_emitted(creature, "defeated")
	creature.take_scratch(Vector2.RIGHT)
	assert_true(creature.is_defeated())
	assert_signal_emit_count(creature, "defeated", 1)
	assert_signal_emitted_with_parameters(creature, "defeated", [creature])


func test_defeated_creature_does_not_count_twice_and_stops_colliding() -> void:
	var creature := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	watch_signals(creature)
	for i in 5:
		creature.take_scratch()
	assert_signal_emit_count(creature, "defeated", 1)
	assert_eq(creature.collision_layer, 0)


func test_scratch_pushes_the_creature_back() -> void:
	var grid := _grid(["#############", "#...........#", "#############"])
	var creature := _creature(grid, Vector2i(6, 1))
	_target.position = MazeGrid.cell_to_position(Vector2i(11, 1))
	var start := creature.position
	creature.take_scratch(Vector2.LEFT)
	await wait_physics_frames(5)
	assert_lt(creature.position.x, start.x, "Foi empurrada para longe do golpe")


func test_defeat_feedback_has_no_blood() -> void:
	# O feedback é só piscar e sumir encolhendo: a cena não tem partículas nem
	# nós de sangue.
	var creature := _creature(_grid(["###", "#.#", "###"]), Vector2i(1, 1))
	for child in creature.get_children():
		assert_false(child is GPUParticles2D or child is CPUParticles2D)
	creature.take_scratch()
	assert_gt((creature.get_node("Sprite") as Sprite2D).modulate.r, 1.0, "Piscou")
