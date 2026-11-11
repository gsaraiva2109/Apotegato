class_name StockMenu
extends CanvasLayer
## Tela do estoque da apotecária: uma linha para cada ingrediente guardado, com
## ícone, nome e quantidade. Acessível pela estante da cabana. Esc ou o botão
## Voltar fecham.

## Emitido sempre que a tela se fecha.
signal closed

const ICON_DIR := "res://assets/art/ingredients"
const FALLBACK_ICON := "res://assets/art/ingredients/pickup_placeholder.png"
const ICON_SIZE := Vector2(32, 32)
const MAX_LIST_HEIGHT := 288.0

## O estoque mostrado. Por padrão é o da campanha; os testes podem trocar.
var stock: Stock = null

@onready var _list: VBoxContainer = $Root/Center/Panel/Layout/Scroll/List
@onready var _scroll: ScrollContainer = $Root/Center/Panel/Layout/Scroll
@onready var _empty_label: Label = $Root/Center/Panel/Layout/EmptyLabel
@onready var _total_label: Label = $Root/Center/Panel/Layout/TotalLabel
@onready var _back_button: Button = $Root/Center/Panel/Layout/BackButton


func _ready() -> void:
	_scroll.custom_minimum_size.y = MAX_LIST_HEIGHT
	_back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Abre a tela com o conteúdo atual do estoque.
func open() -> void:
	if stock == null:
		stock = GameState.stock
	refresh()
	visible = true
	_back_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Refaz a lista a partir do estoque.
func refresh() -> void:
	for row in _list.get_children():
		_list.remove_child(row)
		row.queue_free()
	var source := stock if stock != null else GameState.stock
	for id in source.ids():
		_list.add_child(_new_row(id, source.count(id)))
	_empty_label.visible = source.is_empty()
	_scroll.visible = not source.is_empty()
	_total_label.text = "Total: %d" % source.total_count()


## Quantas linhas (ingredientes diferentes) a lista mostra.
func row_count() -> int:
	return _list.get_child_count()


## Linha de um ingrediente, ou null se ele não está na lista.
func get_row(id: String) -> HBoxContainer:
	return _list.get_node_or_null(id.to_pascal_case()) as HBoxContainer


## Caminho do ícone do ingrediente: o arquivo com o nome do id, se existir, ou o
## ícone provisório.
static func icon_path(id: String) -> String:
	var path := "%s/%s.png" % [ICON_DIR, id]
	return path if ResourceLoader.exists(path) else FALLBACK_ICON


func _new_row(id: String, amount: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = id.to_pascal_case()
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.texture = load(icon_path(id))
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)

	var ingredient := IngredientData.get_ingredient(id)
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.text = ingredient.display_name if ingredient != null else id
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var amount_label := Label.new()
	amount_label.name = "AmountLabel"
	amount_label.text = "x%d" % amount
	row.add_child(amount_label)
	return row
