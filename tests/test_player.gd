extends GutTest
## Confere o movimento do Mingau, a colisão com a sala de teste e a câmera.

const PlayerScene := preload("res://scenes/player/player.tscn")
const RoomScene := preload("res://scenes/cabin/test_room.tscn")


func test_diagonal_is_not_faster() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	var straight := player.velocity_for(Vector2.RIGHT).length()
	var diagonal := player.velocity_for(Vector2(1, 1)).length()
	assert_almost_eq(diagonal, straight, 0.001)
	assert_almost_eq(straight, player.speed, 0.001)


func test_no_input_means_standing_still() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	assert_eq(player.velocity_for(Vector2.ZERO), Vector2.ZERO)


func test_sprite_uses_nearest_filter() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	var sprite: Sprite2D = player.get_node("Sprite")
	assert_not_null(sprite.texture)
	assert_eq(sprite.texture_filter, CanvasItem.TEXTURE_FILTER_NEAREST)


func test_camera_zooms_and_follows_player() -> void:
	var player: Player = autofree(PlayerScene.instantiate())
	var camera: Camera2D = player.get_node("Camera")
	assert_gt(camera.zoom.x, 1.0, "A câmera deve ter zoom")
	assert_eq(camera.get_parent(), player, "A câmera segue o gato por ser filha dele")


func test_room_limits_the_camera() -> void:
	var room: Node2D = autofree(RoomScene.instantiate())
	add_child(room)
	await wait_physics_frames(1)
	var camera: Camera2D = room.get_node("Player/Camera")
	assert_eq(camera.limit_right, 960)
	assert_eq(camera.limit_bottom, 640)


func test_walls_stop_the_player() -> void:
	var room: Node2D = autofree(RoomScene.instantiate())
	add_child(room)
	var player: Player = room.get_node("Player")
	player.position = Vector2(100, 320)
	await wait_physics_frames(2)
	# anda para a esquerda até a parede (borda interna em x = 32)
	for i in 120:
		player.velocity = Vector2.LEFT * player.speed
		player.move_and_slide()
	assert_gt(player.position.x, 32.0, "O gato não atravessa a parede")
	assert_lt(player.position.x, 60.0, "O gato chegou perto da parede")
