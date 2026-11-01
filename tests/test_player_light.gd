extends GutTest
## Confere a luz do gato no andar: escuridão, círculo que acompanha o Mingau,
## crescimento a cada derrota e volta a 0,6 ao trocar de andar.

const FloorScene := preload("res://scenes/region/floor.tscn")
const LightScene := preload("res://scenes/region/player_light.tscn")

var _floor: RegionFloor


func before_each() -> void:
	GameState.new_game()
	GameState.start_region(Regions.CERRADO)
	_floor = autofree(FloorScene.instantiate())
	add_child(_floor)
	await wait_physics_frames(2)


func after_each() -> void:
	get_tree().paused = false
	GameState.new_game()


func _light() -> PlayerLight:
	return _floor.get_node("World/Player/Light")


func test_light_starts_at_the_base_scale() -> void:
	assert_almost_eq(_light().texture_scale, 0.6, 0.0001)
	assert_eq(_light().defeated, 0)


func test_each_defeat_grows_the_light() -> void:
	_light().add_defeat()
	assert_almost_eq(_light().texture_scale, 0.72, 0.0001)
	for i in 9:
		_light().add_defeat()
	assert_almost_eq(_light().texture_scale, 1.8, 0.0001)
	_light().add_defeat()
	assert_almost_eq(_light().texture_scale, 1.8, 0.0001, "Teto de 1,8")


func test_light_goes_back_to_the_base_on_a_new_floor() -> void:
	_light().add_defeat()
	_light().add_defeat()
	assert_gt(_light().texture_scale, 0.6)
	_floor._on_door_choice_made(DoorMenu.UP)
	assert_almost_eq(_light().texture_scale, 0.6, 0.0001)
	assert_eq(_light().defeated, 0)


func test_light_goes_back_to_the_base_on_a_region_change() -> void:
	_light().add_defeat()
	_floor._on_region_selected(Regions.LITORAL)
	assert_almost_eq(_light().texture_scale, 0.6, 0.0001)


func test_light_follows_the_player() -> void:
	var player: Player = _floor.get_node("World/Player")
	assert_eq(_light().get_parent(), player, "Filha do gato, então acompanha")
	player.position = Vector2(300, 200)
	assert_eq(_light().global_position, player.global_position)


func test_light_has_a_texture_and_no_shadow_cost() -> void:
	assert_not_null(_light().texture)
	assert_true(_light().enabled)
	assert_false(_light().shadow_enabled)


func test_floor_is_dark() -> void:
	var darkness: CanvasModulate = _floor.get_node("Darkness")
	assert_lt(darkness.color.get_luminance(), 0.1)


func test_interface_is_not_darkened() -> void:
	# O CanvasModulate só afeta a camada dele (a padrão); o HUD fica em outra.
	var darkness: CanvasModulate = _floor.get_node("Darkness")
	var hud: CanvasLayer = _floor.get_node("Hud")
	assert_null(darkness.get_canvas_layer_node())
	assert_ne(hud.layer, 0)


func test_project_uses_the_compatibility_renderer() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility"
	)


func test_standalone_light_scene_starts_at_the_base() -> void:
	var light: PlayerLight = autofree(LightScene.instantiate())
	add_child(light)
	assert_almost_eq(light.texture_scale, 0.6, 0.0001)
