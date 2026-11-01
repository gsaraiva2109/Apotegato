extends GutTest
## Confere o estoque da apotecária e como ele soma com a mochila numa entrega.

var _stock: Stock
var _backpack: Backpack


func before_each() -> void:
	_stock = Stock.new()
	_backpack = Backpack.new()


func test_store_and_take_by_id() -> void:
	assert_true(_stock.store("mel", 2))
	assert_eq(_stock.count("mel"), 2)
	assert_true(_stock.take("mel"))
	assert_eq(_stock.count("mel"), 1)
	assert_true(_stock.take("mel"))
	assert_true(_stock.is_empty())


func test_taking_more_than_there_is_changes_nothing() -> void:
	_stock.store("mel")
	assert_false(_stock.take("mel", 2))
	assert_false(_stock.take("sardinha"))
	assert_eq(_stock.count("mel"), 1)


func test_stock_has_no_slot_limit() -> void:
	for ingredient in IngredientData.get_all_ingredients():
		assert_true(_stock.store(ingredient.id))
	assert_eq(_stock.ids().size(), IngredientData.get_all_ingredients().size())
	assert_gt(_stock.ids().size(), Backpack.MAX_SLOTS)


func test_invalid_amounts_and_ids_are_ignored() -> void:
	assert_false(_stock.store("mel", 0))
	assert_false(_stock.store(""))
	assert_false(_stock.take("mel", 0))
	assert_true(_stock.is_empty())


func test_changed_is_emitted_on_every_change() -> void:
	watch_signals(_stock)
	_stock.store("mel")
	_stock.take("mel")
	assert_signal_emit_count(_stock, "changed", 2)


func test_stock_items_count_to_complete_a_delivery() -> void:
	# Queimaduras pede copaíba, pele de tilápia e mel (Tabela 1): falta o mel
	# na mochila, e o estoque completa.
	_backpack.add("resina_copaiba")
	_backpack.add("pele_tilapia")
	assert_false(IngredientData.is_condition_satisfied("queimaduras", _backpack.ids()))
	_stock.store("mel")
	var ids := _stock.ids_for_delivery(_backpack)
	assert_true(IngredientData.is_condition_satisfied("queimaduras", ids))


func test_delivery_ids_do_not_repeat() -> void:
	_backpack.add("mel")
	_stock.store("mel")
	_stock.store("sardinha")
	assert_eq(_stock.ids_for_delivery(_backpack), ["mel", "sardinha"])


func test_or_rule_works_with_stock_ids() -> void:
	# Anemia ferropriva: camu-camu OU acerola cobre o terceiro requisito.
	_backpack.add("castanha_caju")
	_backpack.add("figado_bovino")
	_stock.store("acerola")
	assert_true(
		IngredientData.is_condition_satisfied(
			"anemia_ferropriva", _stock.ids_for_delivery(_backpack)
		)
	)
