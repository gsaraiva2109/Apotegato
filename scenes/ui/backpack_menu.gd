class_name BackpackMenu
extends CanvasLayer
## Tela da mochila, aberta na cabana: mostra os 6 espaços (ícone, nome e
## quantidade) e entrega os ingredientes à apotecária para o paciente atual.
## Depois da entrega, cada sobra pode ser guardada no estoque ou usada para
## recuperar 1 coração. Esc, o atalho da mochila ou o botão Voltar fecham.
##
## A regra da entrega está em `Delivery`; aqui só se mostra o resultado. Quem
## cuida do paciente (diálogo, saída da cabana) escuta `delivery_completed`.

## Emitido sempre que a tela se fecha.
signal closed
## Emitido quando a entrega cobre a condição. Os ingredientes já foram gastos.
signal delivery_completed(condition: String)
## Emitido a cada entrega, com o resultado (para o diálogo escolher a fala).
signal delivered(result: DeliveryResult)

const ICON_DIR := "res://assets/art/ingredients"
const FALLBACK_ICON := "res://assets/art/ingredients/pickup_placeholder.png"
const ICON_SIZE := Vector2(32, 32)

## Falas da apotecária para cada resultado, do roteiro (seção 5).
const TEXT_EMPTY := (
	"Tudo bem. Consulte o diário, escolha uma região e comece por lá. "
	+ "Você pode voltar quando encontrar algum item."
)
const TEXT_PARTIAL := (
	"Obrigada. Vou guardar esses ingredientes. Ainda faltam: %s. "
	+ "Você pode continuar a busca e voltar quando tiver o restante."
)
const TEXT_COMPLETE := "Aqui está tudo o que eu precisava."
const TEXT_NO_PATIENT := "Não há ninguém para atender agora."
const TEXT_SURPLUS := (
	"Estes ingredientes não são necessários para o paciente atual, mas serão úteis "
	+ "depois. Vou guardá-los no estoque para não desperdiçarmos nada."
)

## Mochila, estoque e corações usados pela tela. Por padrão são os da campanha;
## os testes podem trocar. `hearts` vem do Mingau na cabana; sem ele, o botão
## de usar a sobra não recupera nada.
var backpack: Backpack = null
var stock: Stock = null
var hearts: Hearts = null
## Condição do paciente atual (id do CSV). Vazia: não há entrega a fazer.
var condition: String = ""

var _delivery: Delivery = null

@onready var _slots: VBoxContainer = $Root/Center/Panel/Layout/Slots
@onready var _count_label: Label = $Root/Center/Panel/Layout/CountLabel
@onready var _message_label: Label = $Root/Center/Panel/Layout/MessageLabel
@onready var _surplus_box: VBoxContainer = $Root/Center/Panel/Layout/SurplusBox
@onready var _surplus_list: VBoxContainer = $Root/Center/Panel/Layout/SurplusBox/SurplusList
@onready var _deliver_button: Button = $Root/Center/Panel/Layout/Buttons/DeliverButton
@onready var _back_button: Button = $Root/Center/Panel/Layout/Buttons/BackButton


func _ready() -> void:
	_deliver_button.pressed.connect(deliver)
	_back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("backpack"):
		close()
		get_viewport().set_input_as_handled()


## Abre a tela. `patient_condition` é a condição do paciente atual ("" se não há
## paciente, e então só dá para ver a mochila).
func open(patient_condition: String = "") -> void:
	if backpack == null:
		backpack = GameState.backpack
	if stock == null:
		stock = GameState.stock
	condition = patient_condition
	_delivery = Delivery.new(condition, backpack, stock) if not condition.is_empty() else null
	_message_label.text = ""
	refresh()
	visible = true
	if _deliver_button.disabled:
		_back_button.grab_focus()
	else:
		_deliver_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Entrega os ingredientes ao paciente atual e mostra o que a apotecária diz.
## Devolve null se não há paciente.
func deliver() -> DeliveryResult:
	if _delivery == null:
		_message_label.text = TEXT_NO_PATIENT
		return null
	var result := _delivery.deliver()
	match result.outcome:
		Delivery.Outcome.EMPTY_BACKPACK:
			_message_label.text = TEXT_EMPTY
		Delivery.Outcome.PARTIAL:
			_message_label.text = TEXT_PARTIAL % result.missing_text()
		Delivery.Outcome.COMPLETE:
			_message_label.text = TEXT_COMPLETE
	if not result.surplus.is_empty():
		_message_label.text += "\n" + TEXT_SURPLUS
	refresh()
	delivered.emit(result)
	if result.outcome == Delivery.Outcome.COMPLETE:
		delivery_completed.emit(condition)
	return result


## Guarda uma unidade da sobra no estoque.
func store_surplus(id: String) -> bool:
	if _delivery == null or not _delivery.store_surplus(id):
		return false
	refresh()
	return true


## Usa uma unidade da sobra para recuperar 1 coração. Devolve quantos recuperou.
func use_surplus(id: String) -> int:
	if _delivery == null:
		return 0
	var recovered := _delivery.use_surplus(id, hearts)
	refresh()
	return recovered


## Refaz os 6 espaços e a lista de sobras.
func refresh() -> void:
	_clear(_slots)
	_clear(_surplus_list)
	var ids := backpack.ids()
	for index in Backpack.MAX_SLOTS:
		if index < ids.size():
			_slots.add_child(_new_slot(index, ids[index], backpack.count(ids[index])))
		else:
			_slots.add_child(_new_slot(index, "", 0))
	_count_label.text = "Mochila %d/%d" % [backpack.used_slots(), Backpack.MAX_SLOTS]
	_deliver_button.disabled = _delivery == null
	var surplus := _delivery.surplus() if _delivery != null else {}
	for id: String in surplus:
		_surplus_list.add_child(_new_surplus_row(id, surplus[id]))
	_surplus_box.visible = not surplus.is_empty() and _message_shows_delivery()


## Linha do espaço `index` (0 a 5), ou null se não existe.
func get_slot(index: int) -> HBoxContainer:
	return _slots.get_node_or_null("Slot%d" % index) as HBoxContainer


## Linha de uma sobra, ou null se ela não está na lista.
func get_surplus_row(id: String) -> HBoxContainer:
	return _surplus_list.get_node_or_null(id.to_pascal_case()) as HBoxContainer


## Caminho do ícone do ingrediente: o arquivo com o nome do id, se existir, ou o
## ícone provisório.
static func icon_path(id: String) -> String:
	var path := "%s/%s.png" % [ICON_DIR, id]
	return path if ResourceLoader.exists(path) else FALLBACK_ICON


func _message_shows_delivery() -> bool:
	return not _message_label.text.is_empty()


func _clear(box: Container) -> void:
	for child in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _new_slot(index: int, id: String, amount: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Slot%d" % index
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	var amount_label := Label.new()
	amount_label.name = "AmountLabel"
	row.add_child(amount_label)

	if id.is_empty():
		name_label.text = "Vazio"
		name_label.modulate = Color(1, 1, 1, 0.5)
	else:
		icon.texture = load(icon_path(id))
		name_label.text = _display_name(id)
		amount_label.text = "x%d" % amount
	return row


func _new_surplus_row(id: String, amount: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = id.to_pascal_case()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.name = "NameLabel"
	label.text = "%s x%d" % [_display_name(id), amount]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	var store_button := Button.new()
	store_button.name = "StoreButton"
	store_button.text = "Guardar"
	store_button.pressed.connect(store_surplus.bind(id))
	row.add_child(store_button)

	var use_button := Button.new()
	use_button.name = "UseButton"
	use_button.text = "Usar (+1 coração)"
	use_button.disabled = hearts == null or hearts.is_full()
	use_button.pressed.connect(use_surplus.bind(id))
	row.add_child(use_button)
	return row


func _display_name(id: String) -> String:
	var ingredient := IngredientData.get_ingredient(id)
	return ingredient.display_name if ingredient != null else id
