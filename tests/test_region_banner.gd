extends GutTest
## Confere a faixa com o nome da região.

const BannerScene := preload("res://scenes/ui/region_banner.tscn")
const FloorScene := preload("res://scenes/region/floor.tscn")


func after_each() -> void:
	get_tree().paused = false
	GameState.new_game()


func test_starts_hidden() -> void:
	var banner: RegionBanner = autofree(BannerScene.instantiate())
	add_child(banner)
	assert_false(banner.get_node("Root").visible)


func test_show_region_shows_name_and_floor() -> void:
	var banner: RegionBanner = autofree(BannerScene.instantiate())
	add_child(banner)
	banner.show_region(Regions.CERRADO, 1)
	assert_true(banner.get_node("Root").visible)
	assert_eq(banner.get_node("Root/Plate/Layout/RegionName").text, "Cerrado")
	assert_eq(banner.get_node("Root/Plate/Layout/FloorLabel").text, "Andar 1")


func test_banner_shows_on_the_first_floor_only() -> void:
	GameState.new_game()
	GameState.start_region(Regions.CAATINGA)
	var floor_node: RegionFloor = autofree(FloorScene.instantiate())
	add_child(floor_node)
	await wait_physics_frames(2)
	var root: Control = floor_node.get_node("RegionBanner/Root")
	assert_true(root.visible, "Entrou na região: mostra a faixa")
	root.hide()
	GameState.climb_floor()
	floor_node.generate_floor()
	assert_false(root.visible, "Andar 2 não repete a faixa")
