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
