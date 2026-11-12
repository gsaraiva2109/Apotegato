extends GutTest
## Confere a tela da mochila: 6 espaços, entrega, mensagens e sobras.

const BackpackMenuScene := preload("res://scenes/ui/backpack_menu.tscn")

var _menu: BackpackMenu
var _backpack: Backpack
var _stock: Stock
var _hearts: Hearts


func before_each() -> void:
	_backpack = Backpack.new()
	_stock = Stock.new()
	_hearts = Hearts.new()
	_menu = autofree(BackpackMenuScene.instantiate())
	_menu.backpack = _backpack
	_menu.stock = _stock
	_menu.hearts = _hearts
	add_child(_menu)


func _message() -> String:
	return (_menu.get_node("Root/Center/Panel/Layout/MessageLabel") as Label).text


func test_starts_closed() -> void:
	assert_false(_menu.is_open())


func test_shows_six_slots_with_icon_name_and_amount() -> void:
	_backpack.add("mel", 3)
	_menu.open()
	for index in Backpack.MAX_SLOTS:
		assert_not_null(_menu.get_slot(index))
	var slot := _menu.get_slot(0)
	assert_not_null((slot.get_node("Icon") as TextureRect).texture)
	assert_eq((slot.get_node("NameLabel") as Label).text, "Mel")
	assert_eq((slot.get_node("AmountLabel") as Label).text, "x3")
	assert_eq((_menu.get_slot(1).get_node("NameLabel") as Label).text, "Vazio")


func test_deliver_is_disabled_without_a_patient() -> void:
	_menu.open()
	assert_true(_menu.get_node("Root/Center/Panel/Layout/Buttons/DeliverButton").disabled)
	assert_null(_menu.deliver())


func test_empty_backpack_shows_the_script_line() -> void:
	_menu.open("anemia_ferropriva")
	var result := _menu.deliver()
	assert_eq(result.outcome, Delivery.Outcome.EMPTY_BACKPACK)
	assert_eq(_message(), BackpackMenu.TEXT_EMPTY)


func test_partial_delivery_says_what_is_missing() -> void:
	_backpack.add("castanha_caju")
	_menu.open("anemia_ferropriva")
	_menu.deliver()
	assert_string_contains(_message(), "Ainda faltam: Fígado bovino e Camu-camu ou Acerola.")
	assert_eq(_stock.count("castanha_caju"), 1)


func test_complete_delivery_emits_the_signal() -> void:
	for id in ["castanha_caju", "figado_bovino", "acerola"]:
		_backpack.add(id)
	_menu.open("anemia_ferropriva")
	watch_signals(_menu)
	_menu.deliver()
	assert_signal_emitted_with_parameters(_menu, "delivery_completed", ["anemia_ferropriva"])


func test_partial_delivery_does_not_emit_completed() -> void:
	_backpack.add("castanha_caju")
	_menu.open("anemia_ferropriva")
	watch_signals(_menu)
	_menu.deliver()
	assert_signal_not_emitted(_menu, "delivery_completed")
	assert_signal_emitted(_menu, "delivered")


func test_surplus_row_can_be_stored() -> void:
	_backpack.add("mel")
	_menu.open("anemia_ferropriva")
	_menu.deliver()
	assert_not_null(_menu.get_surplus_row("mel"))
	assert_string_contains(_message(), "estoque")
	assert_true(_menu.store_surplus("mel"))
	assert_eq(_stock.count("mel"), 1)
	assert_null(_menu.get_surplus_row("mel"))


func test_surplus_row_can_heal() -> void:
	_backpack.add("mel")
	_hearts.hurt(4)
	_menu.open("anemia_ferropriva")
	_menu.deliver()
	assert_eq(_menu.use_surplus("mel"), 2)
	assert_eq(_hearts.current, 12)
	assert_true(_backpack.is_empty())


func test_surplus_row_heals_half_a_heart_and_spends_the_ingredient() -> void:
	_backpack.add("mel")
	_hearts.hurt(1)
	_menu.open("anemia_ferropriva")
	_menu.deliver()
	assert_eq(_menu.use_surplus("mel"), 1)
	assert_true(_hearts.is_full())
	assert_true(_backpack.is_empty())


func test_use_button_is_off_with_full_hearts_and_nothing_is_spent() -> void:
	_backpack.add("mel")
	_menu.open("anemia_ferropriva")
	_menu.deliver()
	var button: Button = _menu.get_surplus_row("mel").get_node("UseButton")
	assert_true(button.disabled)
	assert_eq(_menu.use_surplus("mel"), 0)
	assert_eq(_backpack.count("mel"), 1)


func test_use_button_text_shows_how_much_it_heals() -> void:
	_backpack.add("mel")
	_hearts.hurt(4)
	_menu.open("anemia_ferropriva")
	_menu.deliver()
	var button: Button = _menu.get_surplus_row("mel").get_node("UseButton")
	assert_eq(button.text, "Usar (+1 coração)")
	assert_false(button.disabled)
	assert_eq(BackpackMenu.use_text(_hearts), "Usar (+1 coração)")
	_hearts.restore()
	_hearts.hurt(1)
	assert_eq(BackpackMenu.use_text(_hearts), "Usar (+½ coração)")


func test_close_emits_closed() -> void:
	_menu.open()
	watch_signals(_menu)
	_menu.close()
	assert_false(_menu.is_open())
	assert_signal_emitted(_menu, "closed")
