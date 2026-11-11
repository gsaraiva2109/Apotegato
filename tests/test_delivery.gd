extends GutTest
## Confere a regra de entrega: entrega parcial, mochila vazia, completa com a
## regra "ou" e o destino das sobras.

var _backpack: Backpack
var _stock: Stock
var _delivery: Delivery


func before_each() -> void:
	_backpack = Backpack.new()
	_stock = Stock.new()
	# anemia_ferropriva: castanha_caju, figado_bovino e (camu_camu ou acerola).
	_delivery = Delivery.new("anemia_ferropriva", _backpack, _stock)


func test_empty_backpack_changes_nothing() -> void:
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.EMPTY_BACKPACK)
	assert_true(_stock.is_empty())


func test_partial_delivery_goes_to_stock_and_lists_what_is_missing() -> void:
	_backpack.add("castanha_caju")
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.PARTIAL)
	assert_eq(_stock.count("castanha_caju"), 1)
	assert_true(_backpack.is_empty())
	assert_eq(result.missing.size(), 2)
	assert_eq(result.missing_text(), "Fígado bovino e Camu-camu ou Acerola")


func test_second_delivery_adds_to_the_first() -> void:
	_backpack.add("castanha_caju")
	_delivery.deliver()
	_backpack.add("figado_bovino")
	_backpack.add("acerola")
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.COMPLETE)
	assert_true(result.missing.is_empty())


func test_either_option_of_an_or_group_is_enough() -> void:
	for option in ["camu_camu", "acerola"]:
		_backpack = Backpack.new()
		_stock = Stock.new()
		_delivery = Delivery.new("anemia_ferropriva", _backpack, _stock)
		for id in ["castanha_caju", "figado_bovino", option]:
			_backpack.add(id)
		assert_eq(_delivery.deliver().outcome, Delivery.Outcome.COMPLETE, option)


func test_complete_delivery_spends_one_of_each_requirement() -> void:
	_stock.store("castanha_caju", 2)
	for id in ["figado_bovino", "acerola", "camu_camu"]:
		_backpack.add(id)
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.COMPLETE)
	assert_eq(_stock.count("castanha_caju"), 1, "Gasta só uma unidade")
	assert_eq(_stock.count("figado_bovino"), 0)
	assert_eq(result.consumed.size(), 3)


func test_stock_alone_can_complete_even_with_an_empty_backpack() -> void:
	for id in ["castanha_caju", "figado_bovino", "camu_camu"]:
		_stock.store(id)
	assert_true(_delivery.can_complete())
	assert_eq(_delivery.deliver().outcome, Delivery.Outcome.COMPLETE)


func test_empty_backpack_with_incomplete_stock_still_reports_empty() -> void:
	_stock.store("castanha_caju")
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.EMPTY_BACKPACK)
	assert_eq(_stock.count("castanha_caju"), 1)


func test_unneeded_ingredients_are_surplus_and_stay_in_the_backpack() -> void:
	_backpack.add("castanha_caju")
	_backpack.add("mel", 2)
	var result := _delivery.deliver()
	assert_eq(result.surplus, {"mel": 2})
	assert_eq(_backpack.count("mel"), 2)


func test_only_surplus_in_the_backpack_is_a_partial_delivery() -> void:
	_backpack.add("mel")
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.PARTIAL)
	assert_eq(result.missing.size(), 3)
	assert_eq(result.surplus, {"mel": 1})


func test_surplus_can_be_stored() -> void:
	_backpack.add("mel")
	_delivery.deliver()
	assert_true(_delivery.store_surplus("mel"))
	assert_eq(_stock.count("mel"), 1)
	assert_true(_backpack.is_empty())
	assert_false(_delivery.store_surplus("mel"))


func test_needed_ingredient_is_not_surplus() -> void:
	_backpack.add("castanha_caju", 3)
	assert_false(_delivery.store_surplus("castanha_caju"))


func test_surplus_recovers_one_heart_each() -> void:
	_backpack.add("mel", 2)
	_delivery.deliver()
	var hearts := Hearts.new()
	hearts.hurt(3)
	assert_eq(_delivery.use_surplus("mel", hearts), 1)
	assert_eq(hearts.current, 5)
	assert_eq(_backpack.count("mel"), 1)


func test_surplus_is_kept_when_hearts_are_full() -> void:
	_backpack.add("mel")
	assert_eq(_delivery.use_surplus("mel", Hearts.new()), 0)
	assert_eq(_backpack.count("mel"), 1)


func test_after_completion_the_unused_alternative_is_surplus() -> void:
	for id in ["castanha_caju", "figado_bovino", "acerola", "camu_camu"]:
		_backpack.add(id)
	var result := _delivery.deliver()
	assert_eq(result.outcome, Delivery.Outcome.COMPLETE)
	assert_eq(result.surplus.size(), 1)
	assert_true(_delivery.store_surplus(result.surplus.keys()[0]))


func test_join_labels() -> void:
	assert_eq(Delivery.join_labels([] as Array[String]), "")
	assert_eq(Delivery.join_labels(["A"] as Array[String]), "A")
	assert_eq(Delivery.join_labels(["A", "B"] as Array[String]), "A e B")
	assert_eq(Delivery.join_labels(["A", "B", "C"] as Array[String]), "A, B e C")
