extends GutTest
## Confere a escolha de quadros do Mingau: direção (8), andar e arranhão. A parte
## que depende da folha de arte só roda se ela estiver instalada.

const PlayerScene := preload("res://scenes/player/player.tscn")


func test_direction_index_covers_the_eight_directions() -> void:
	assert_eq(MingauSprites.direction_index(Vector2.DOWN), 0)
	assert_eq(MingauSprites.direction_index(Vector2(1, 1)), 1)
	assert_eq(MingauSprites.direction_index(Vector2.RIGHT), 2)
	assert_eq(MingauSprites.direction_index(Vector2(1, -1)), 3)
	assert_eq(MingauSprites.direction_index(Vector2.UP), 4)
	assert_eq(MingauSprites.direction_index(Vector2(-1, -1)), 5)
	assert_eq(MingauSprites.direction_index(Vector2.LEFT), 6)
	assert_eq(MingauSprites.direction_index(Vector2(-1, 1)), 7)


func test_snap_goes_to_the_nearest_of_the_eight() -> void:
	assert_eq(MingauSprites.snap(Vector2(0.1, 1), Vector2.UP), Vector2.DOWN)
	assert_eq(MingauSprites.snap(Vector2(0.9, 0.8), Vector2.UP), MingauSprites.DIRECTIONS[1])
	assert_eq(MingauSprites.snap(Vector2.ZERO, Vector2.LEFT), Vector2.LEFT)


func test_directions_are_unit_vectors() -> void:
	for direction in MingauSprites.DIRECTIONS:
		assert_almost_eq(direction.length(), 1.0, 0.001)
		assert_eq(MingauSprites.snap(direction, Vector2.ZERO), direction)


func test_walk_frames_cycle_over_the_four_walk_columns() -> void:
	assert_eq(MingauSprites.walk_frame(0.0), MingauSprites.WALK_FIRST)
	assert_eq(MingauSprites.walk_frame(1.0 / MingauSprites.WALK_FPS), MingauSprites.WALK_FIRST + 1)
	assert_eq(MingauSprites.walk_frame(0.5), MingauSprites.WALK_FIRST)
	assert_eq(MingauSprites.walk_frame(-1.0), MingauSprites.WALK_FIRST)


func test_scratch_runs_windup_hit_and_recover_then_ends() -> void:
	var step := MingauSprites.SCRATCH_FRAME_SECONDS
	assert_eq(MingauSprites.scratch_frame(0.0), MingauSprites.WINDUP_FRAME)
	assert_eq(MingauSprites.scratch_frame(step * 1.5), MingauSprites.HIT_FRAME)
	assert_eq(MingauSprites.scratch_frame(step * 2.5), MingauSprites.RECOVER_FRAME)
	assert_eq(MingauSprites.scratch_frame(step * 3.1), -1)


func test_player_works_without_the_sheet() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	add_child(player)
	assert_eq(player.has_art(), MingauSprites.is_installed())


func test_player_shows_scratch_frames_in_the_facing_row() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	add_child(player)
	if not player.has_art():
		pending("Folha do Mingau não instalada (tools/fetch_assets.sh)")
		return
	player.facing = Vector2.RIGHT
	await wait_physics_frames(1)
	assert_eq(player.current_frame(), 2 * MingauSprites.COLUMNS + MingauSprites.IDLE_FRAME)
	player._scratch_time = 0.0
	await wait_physics_frames(1)
	var column := player.current_frame() % MingauSprites.COLUMNS
	assert_eq(column, MingauSprites.WINDUP_FRAME)
