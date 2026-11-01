extends GutTest
## Confere o menu da porta do andar: as três opções, o número do próximo andar e
## o fechamento. Não existe opção de descer.

const DoorMenuScene := preload("res://scenes/ui/door_menu.tscn")

var _menu: DoorMenu


func before_each() -> void:
	_menu = autofree(DoorMenuScene.instantiate())
	add_child(_menu)


func _button(button_name: String) -> Button:
	return _menu.get_node("Root/Center/Panel/Layout/%s" % button_name)


func test_starts_closed() -> void:
	assert_false(_menu.is_open())


func test_has_exactly_three_choices_and_a_cancel() -> void:
	var layout := _menu.get_node("Root/Center/Panel/Layout")
	var buttons := layout.get_children().filter(func(node: Node) -> bool: return node is Button)
	assert_eq(buttons.size(), 4)
	_menu.open(3)
	assert_eq(_button("UpButton").text, "Subir para o andar 4")
	assert_eq(_button("CabinButton").text, "Voltar à cabana")
	assert_eq(_button("RegionButton").text, "Ir ao andar 1 de outra região")


func test_each_choice_is_emitted_and_closes() -> void:
	var expected := {
		"UpButton": DoorMenu.UP,
		"CabinButton": DoorMenu.CABIN,
		"RegionButton": DoorMenu.OTHER_REGION,
	}
	for button_name: String in expected:
		_menu.open(1)
		watch_signals(_menu)
		_button(button_name).pressed.emit()
		assert_signal_emitted_with_parameters(_menu, "choice_made", [expected[button_name]])
		assert_signal_emitted(_menu, "closed")
		assert_false(_menu.is_open())


func test_cancel_closes_without_choosing() -> void:
	_menu.open(1)
	watch_signals(_menu)
	_button("CancelButton").pressed.emit()
	assert_signal_emitted(_menu, "closed")
	assert_signal_not_emitted(_menu, "choice_made")


func test_opening_focuses_the_first_option() -> void:
	_menu.open(1)
	assert_true(_button("UpButton").has_focus())
