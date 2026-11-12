extends GutTest
## Confere o texto de região e andar da interface da exploração.

const HudScene := preload("res://scenes/ui/hud.tscn")


func test_location_text_has_region_name_and_floor() -> void:
	assert_eq(Hud.location_text(Regions.AMAZONIA, 1), "Amazônia - Andar 1")
	assert_eq(Hud.location_text(Regions.CAMPOS_RIOS, 12), "Campos e Rios - Andar 12")


func test_show_location_updates_the_label() -> void:
	var hud: Hud = autofree(HudScene.instantiate())
	add_child(hud)
	hud.show_location(Regions.MATA_ATLANTICA, 3)
	var label: Label = hud.get_node("Root/LocationPanel/LocationLabel")
	assert_eq(label.text, "Mata Atlântica - Andar 3")


func test_backpack_text_lists_names_and_amounts() -> void:
	var backpack := Backpack.new()
	assert_eq(Hud.backpack_text(backpack), "Mochila 0/6")
	backpack.add("camu_camu", 2)
	backpack.add("buriti")
	assert_eq(Hud.backpack_text(backpack), "Mochila 2/6\nCamu-camu x2\nBuriti x1")


func test_show_backpack_updates_the_label() -> void:
	var hud: Hud = autofree(HudScene.instantiate())
	add_child(hud)
	var backpack := Backpack.new()
	backpack.add("mel")
	hud.show_backpack(backpack)
	var label: Label = hud.get_node("Root/BackpackPanel/BackpackLabel")
	assert_eq(label.text, "Mochila 1/6\nMel x1")


func test_message_shows_and_then_hides() -> void:
	var hud: Hud = autofree(HudScene.instantiate())
	add_child(hud)
	var label: Label = hud.get_node("Root/MessageLabel")
	assert_false(label.visible)
	hud.show_message("Pegou Mel")
	assert_true(label.visible)
	assert_eq(label.text, "Pegou Mel")
	hud.get_node("MessageTimer").timeout.emit()
	assert_false(label.visible)


func test_show_hearts_fills_and_empties() -> void:
	var hud: Hud = autofree(HudScene.instantiate())
	add_child(hud)
	hud.show_hearts(14, 14)
	assert_eq(hud.full_hearts(), 7)
	assert_eq(hud.half_hearts(), 0)
	hud.show_hearts(6, 14)
	assert_eq(hud.full_hearts(), 3)
	assert_eq(hud.get_node("Root/HeartsBox").get_child_count(), 7)
	hud.show_hearts(0, 14)
	assert_eq(hud.full_hearts(), 0)
	assert_eq(hud.half_hearts(), 0)


func test_show_hearts_with_an_odd_value_shows_a_half_heart() -> void:
	var hud: Hud = autofree(HudScene.instantiate())
	add_child(hud)
	hud.show_hearts(13, 14)
	assert_eq(hud.full_hearts(), 6)
	assert_eq(hud.half_hearts(), 1)
	var box: HBoxContainer = hud.get_node("Root/HeartsBox")
	assert_eq(
		(box.get_child(6) as TextureRect).texture, Hud.HEART_HALF, "O último fica pela metade"
	)
	hud.show_hearts(1, 14)
	assert_eq(hud.full_hearts(), 0)
	assert_eq(hud.half_hearts(), 1)
	assert_eq((box.get_child(0) as TextureRect).texture, Hud.HEART_HALF)
	assert_eq((box.get_child(1) as TextureRect).texture, Hud.HEART_EMPTY)


func test_heart_texture_matches_each_fill() -> void:
	assert_eq(Hud.heart_texture(Hearts.Fill.FULL), Hud.HEART_FULL)
	assert_eq(Hud.heart_texture(Hearts.Fill.HALF), Hud.HEART_HALF)
	assert_eq(Hud.heart_texture(Hearts.Fill.EMPTY), Hud.HEART_EMPTY)


func test_light_fraction_goes_from_empty_to_full() -> void:
	assert_eq(Hud.light_fraction(0), 0.0)
	assert_almost_eq(Hud.light_fraction(5), 0.5, 0.001)
	assert_almost_eq(Hud.light_fraction(10), 1.0, 0.001)
	assert_eq(Hud.light_fraction(50), 1.0, "A luz tem teto")


func test_show_light_fills_the_bar() -> void:
	var hud: Hud = autofree(HudScene.instantiate())
	add_child(hud)
	hud.show_light(5)
	var bar: ProgressBar = hud.get_node("Root/LightBox/LightBar")
	assert_almost_eq(bar.value, 0.5, 0.001)
