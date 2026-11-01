extends GutTest
## Confere o menu de escolha de região: seis opções com nome e ícone, escolha
## pelo botão, região excluída e fechamento.

const RegionMenuScene := preload("res://scenes/ui/region_menu.tscn")

var _menu: RegionMenu


func before_each() -> void:
	_menu = autofree(RegionMenuScene.instantiate())
	add_child(_menu)


func test_starts_closed() -> void:
	assert_false(_menu.is_open())


func test_shows_the_six_regions_with_name_and_icon() -> void:
	_menu.open()
	assert_true(_menu.is_open())
	assert_eq(Regions.IDS.size(), 6)
	for region in Regions.IDS:
		var button := _menu.get_button(region)
		assert_true(button.visible)
		assert_eq(button.text, Regions.display_name(region))
		assert_not_null(button.icon, "Ícone de %s" % region)


func test_icons_are_different_for_each_region() -> void:
	var seen := {}
	for region in Regions.IDS:
		var icon: AtlasTexture = _menu.get_button(region).icon
		seen[icon.atlas.resource_path] = true
	assert_eq(seen.size(), 6)


func test_choosing_a_region_emits_it_and_closes() -> void:
	_menu.open()
	watch_signals(_menu)
	_menu.get_button(Regions.CERRADO).pressed.emit()
	assert_signal_emitted_with_parameters(_menu, "region_selected", ["cerrado"])
	assert_signal_emitted(_menu, "closed")
	assert_false(_menu.is_open())


func test_excluded_region_is_hidden() -> void:
	_menu.open(Regions.CAATINGA)
	assert_false(_menu.get_button(Regions.CAATINGA).visible)
	assert_true(_menu.get_button(Regions.AMAZONIA).visible)
	_menu.open()
	assert_true(_menu.get_button(Regions.CAATINGA).visible, "Sem exclusão, aparecem as seis")


func test_back_button_closes_without_choosing() -> void:
	_menu.open()
	watch_signals(_menu)
	_menu.get_node("Root/Center/Panel/Layout/BackButton").pressed.emit()
	assert_signal_emitted(_menu, "closed")
	assert_signal_not_emitted(_menu, "region_selected")
	assert_false(_menu.is_open())


func test_escape_closes_the_menu() -> void:
	_menu.open()
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_process_frames(2)
	assert_false(_menu.is_open())


func test_opening_focuses_a_button_for_keyboard_use() -> void:
	_menu.open()
	assert_true(_menu.get_button(Regions.AMAZONIA).has_focus())
	_menu.open(Regions.AMAZONIA)
	assert_true(_menu.get_button(Regions.CAATINGA).has_focus())
