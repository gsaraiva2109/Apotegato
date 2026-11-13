extends GutTest
## Confere a animação da criatura com folhas de teste (a arte de verdade não fica
## no repositório): quadro por estado, espelhamento e o provisório sem arte.

const CreatureScene := preload("res://scenes/creatures/creature.tscn")

var _target: Node2D


func before_each() -> void:
	_target = autofree(Node2D.new())
	add_child(_target)


func _sheet(frames: int) -> ImageTexture:
	var size := CreatureSprites.CELL_SIZE
	return ImageTexture.create_from_image(
		Image.create(size.x * frames, size.y, false, Image.FORMAT_RGBA8)
	)


func _creature(with_art: bool = true, strong: bool = false) -> Creature:
	var grid := MazeGrid.new(15, 3)
	for x in 15:
		grid.set_blocked(Vector2i(x, 0), true)
		grid.set_blocked(Vector2i(x, 2), true)
	var creature: Creature = autofree(CreatureScene.instantiate())
	creature.position = MazeGrid.cell_to_position(Vector2i(1, 1))
	var data := CreatureCatalog.Entry.new()
	data.damage = 2 if strong else 1
	data.hits = 3
	data.speed = 70.0
	creature.setup(grid, _target, data)
	add_child(creature)
	if with_art:
		creature.use_sheets(
			_sheet(CreatureSprites.WALK_FRAMES), _sheet(CreatureSprites.STRIKE_FRAMES)
		)
	return creature


func _wait_for_state(creature: Creature, state: CreatureBrain.State, frames: int = 120) -> bool:
	for i in frames:
		if creature.brain.state == state:
			return true
		await wait_physics_frames(1)
	return creature.brain.state == state


func test_without_art_keeps_the_placeholder() -> void:
	var creature := _creature(false)
	var sprite: Sprite2D = creature.get_node("Sprite")
	assert_false(creature.has_art())
	assert_eq(sprite.hframes, 1)
	assert_not_null(sprite.texture)


func test_without_art_the_strong_one_is_still_marked() -> void:
	var creature := _creature(false, true)
	assert_eq((creature.get_node("Sprite") as Sprite2D).scale, Vector2.ONE * Creature.STRONG_SCALE)


func test_with_art_the_strong_one_is_not_scaled_or_tinted() -> void:
	var creature := _creature(true, true)
	var sprite: Sprite2D = creature.get_node("Sprite")
	assert_eq(sprite.scale, Vector2.ONE)
	assert_eq(sprite.modulate, Color.WHITE)


func test_idle_shows_the_standing_frame() -> void:
	var creature := _creature()
	var sprite: Sprite2D = creature.get_node("Sprite")
	_target.position = creature.position + Vector2(1000, 0)
	await wait_physics_frames(3)
	assert_true(creature.has_art())
	assert_eq(sprite.hframes, CreatureSprites.WALK_FRAMES)
	assert_eq(sprite.frame, CreatureSprites.STAND_FRAME)


func test_chasing_cycles_the_walk_frames_and_faces_the_movement() -> void:
	var creature := _creature()
	var sprite: Sprite2D = creature.get_node("Sprite")
	_target.position = creature.position + Vector2(100, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.CHASING))
	var seen := {}
	for i in 40:
		await wait_physics_frames(1)
		seen[sprite.frame] = true
	assert_gt(seen.size(), 2, "O quadro muda enquanto anda")
	assert_true(sprite.flip_h, "Vai para a direita: espelhado, pois a arte olha para a esquerda")


func test_chasing_to_the_left_does_not_flip() -> void:
	var creature := _creature()
	creature.position = MazeGrid.cell_to_position(Vector2i(10, 1))
	_target.position = creature.position + Vector2(-100, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.CHASING))
	await wait_physics_frames(5)
	assert_false((creature.get_node("Sprite") as Sprite2D).flip_h)


func test_warning_and_lunge_show_the_strike_frames() -> void:
	var creature := _creature()
	var sprite: Sprite2D = creature.get_node("Sprite")
	_target.position = creature.position + Vector2(20, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.WARNING))
	await wait_physics_frames(1)
	assert_eq(sprite.hframes, CreatureSprites.STRIKE_FRAMES)
	assert_eq(sprite.frame, 0)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.LUNGE))
	await wait_physics_frames(1)
	assert_eq(sprite.frame, 1)
	assert_true(await _wait_for_state(creature, CreatureBrain.State.REST))
	await wait_physics_frames(1)
	assert_eq(sprite.frame, 2)


func test_incomplete_art_falls_back_to_the_placeholder() -> void:
	var creature := _creature(false)
	creature.use_sheets(_sheet(CreatureSprites.WALK_FRAMES), null)
	assert_false(creature.has_art())
	assert_eq((creature.get_node("Sprite") as Sprite2D).hframes, 1)
