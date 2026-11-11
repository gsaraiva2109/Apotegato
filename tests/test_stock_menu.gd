extends GutTest
## Confere a tela do estoque: uma linha com ícone, nome e quantidade para cada
## ingrediente guardado, texto de estoque vazio e fechamento.

const StockMenuScene := preload("res://scenes/ui/stock_menu.tscn")

var _menu: StockMenu
var _stock: Stock


func before_each() -> void:
	_stock = Stock.new()
	_menu = autofree(StockMenuScene.instantiate())
	_menu.stock = _stock
	add_child(_menu)


func test_starts_closed() -> void:
	assert_false(_menu.is_open())


func test_empty_stock_shows_a_message() -> void:
	_menu.open()
	assert_true(_menu.is_open())
	assert_eq(_menu.row_count(), 0)
	assert_true(_menu.get_node("Root/Center/Panel/Layout/EmptyLabel").visible)


func test_lists_each_item_with_icon_name_and_amount() -> void:
	_stock.store("mel", 3)
	_stock.store("buriti")
	_menu.open()
	assert_eq(_menu.row_count(), 2)
	assert_false(_menu.get_node("Root/Center/Panel/Layout/EmptyLabel").visible)
	var row := _menu.get_row("mel")
	assert_not_null(row)
	assert_not_null((row.get_node("Icon") as TextureRect).texture)
	assert_eq((row.get_node("NameLabel") as Label).text, "Mel")
	assert_eq((row.get_node("AmountLabel") as Label).text, "x3")
	assert_eq((_menu.get_row("buriti").get_node("AmountLabel") as Label).text, "x1")
	assert_eq((_menu.get_node("Root/Center/Panel/Layout/TotalLabel") as Label).text, "Total: 4")


func test_reopening_shows_the_new_content() -> void:
	_stock.store("mel")
	_menu.open()
	_menu.close()
	_stock.store("sardinha", 2)
	_stock.take("mel")
	_menu.open()
	await wait_process_frames(2)
	assert_eq(_menu.row_count(), 1)
	assert_not_null(_menu.get_row("sardinha"))


func test_shows_all_26_ingredients() -> void:
	for ingredient in IngredientData.get_all_ingredients():
		_stock.store(ingredient.id)
	_menu.open()
	assert_eq(_menu.row_count(), 26)


func test_uses_game_state_stock_by_default() -> void:
	GameState.new_game()
	GameState.stock.store("pequi", 2)
	var menu: StockMenu = autofree(StockMenuScene.instantiate())
	add_child(menu)
	menu.open()
	assert_eq(menu.row_count(), 1)
	GameState.new_game()


func test_close_hides_and_emits() -> void:
	_menu.open()
	watch_signals(_menu)
	(_menu.get_node("Root/Center/Panel/Layout/BackButton") as Button).pressed.emit()
	assert_false(_menu.is_open())
	assert_signal_emitted(_menu, "closed")


func test_icon_falls_back_to_placeholder() -> void:
	assert_eq(StockMenu.icon_path("ingrediente_sem_arte"), StockMenu.FALLBACK_ICON)
