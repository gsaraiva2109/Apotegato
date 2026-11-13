extends GutTest
## Confere a arte das criaturas: caminhos montados em tempo de execução, quadros
## do andar e do golpe, e o comportamento sem arte instalada (sem erro no console).


func test_paths_follow_the_sprite_folder() -> void:
	assert_eq(
		CreatureSprites.walk_path("capybara"), "res://assets/art/creatures/capybara/andar.png"
	)
	assert_eq(
		CreatureSprites.strike_path("capybara"), "res://assets/art/creatures/capybara/golpe.png"
	)


func test_missing_art_is_not_an_error() -> void:
	assert_false(CreatureSprites.has_art("bicho_que_nao_existe"))
	assert_null(CreatureSprites.load_walk("bicho_que_nao_existe"))
	assert_null(CreatureSprites.load_strike("bicho_que_nao_existe"))


func test_empty_sprite_name_has_no_art() -> void:
	assert_false(CreatureSprites.has_art(""))
	assert_null(CreatureSprites.load_walk(""))
	assert_null(CreatureSprites.load_strike(""))


func test_walk_frame_cycles_through_all_frames() -> void:
	var seen := {}
	for i in 100:
		var frame := CreatureSprites.walk_frame(i / CreatureSprites.WALK_FPS)
		assert_between(frame, 0, CreatureSprites.WALK_FRAMES - 1)
		seen[frame] = true
	assert_eq(seen.size(), CreatureSprites.WALK_FRAMES)
	assert_eq(CreatureSprites.walk_frame(0.0), 0)
	assert_eq(CreatureSprites.walk_frame(-1.0), 0, "Tempo negativo não quebra")


func test_strike_frame_per_state() -> void:
	assert_eq(CreatureSprites.strike_frame(CreatureBrain.State.WARNING), 0)
	assert_eq(CreatureSprites.strike_frame(CreatureBrain.State.LUNGE), 1)
	assert_eq(CreatureSprites.strike_frame(CreatureBrain.State.REST), 2)
	assert_eq(CreatureSprites.strike_frame(CreatureBrain.State.UNAWARE), -1)
	assert_eq(CreatureSprites.strike_frame(CreatureBrain.State.CHASING), -1)
	assert_lt(CreatureSprites.strike_frame(CreatureBrain.State.REST), CreatureSprites.STRIKE_FRAMES)


func test_stand_frame_is_inside_the_walk_sheet() -> void:
	assert_between(CreatureSprites.STAND_FRAME, 0, CreatureSprites.WALK_FRAMES - 1)


func test_installed_art_has_the_expected_sheet_sizes() -> void:
	var checked := 0
	for entry in CreatureCatalog.load_default().all():
		if not CreatureSprites.has_art(entry.sprite):
			continue
		checked += 1
		var cell := CreatureSprites.CELL_SIZE
		var walk := CreatureSprites.load_walk(entry.sprite)
		var strike := CreatureSprites.load_strike(entry.sprite)
		assert_eq(
			walk.get_size(), Vector2(cell.x * CreatureSprites.WALK_FRAMES, cell.y), entry.sprite
		)
		assert_eq(
			strike.get_size(), Vector2(cell.x * CreatureSprites.STRIKE_FRAMES, cell.y), entry.sprite
		)
	if checked == 0:
		pending("Arte dos bichos não instalada (tools/fetch_assets.sh); nada a conferir.")
