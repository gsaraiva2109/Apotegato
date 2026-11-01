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
