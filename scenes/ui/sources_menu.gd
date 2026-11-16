class_name SourcesMenu
extends Control
## Tela Fontes, aberta pelo menu inicial: as referências científicas que
## embasam cada ingrediente, separadas por condição. À esquerda fica a lista de
## condições; à direita, para cada ingrediente da condição escolhida, o resumo,
## as limitações e as referências, com links que abrem no navegador.
##
## Os textos vêm do data/fontes.json (ver `SourcesData`).

## Emitido quando a tela fecha, para o menu devolver o foco ao botão.
signal closed

const LINK_COLOR := "#7a3b12"
const HEADING_COLOR := "#3b2417"
const HEADING_SIZE := 20
const SECTION_SIZE := 16

## Arquivo lido. Só muda nos testes.
var data_path := SourcesData.PATH

var _data := {}
var _current := ""
var _condition_buttons := {}

@onready var _condition_list: VBoxContainer = %ConditionList
@onready var _content: RichTextLabel = %Content
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	hide()
	_data = SourcesData.load_data(data_path)
	_build_condition_buttons()
	_content.meta_clicked.connect(_on_link_clicked)
	_back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Abre a tela na primeira condição, com o foco no botão dela.
func open() -> void:
	var order := SourcesData.get_condition_order(_data)
	show()
	if order.is_empty():
		_back_button.grab_focus()
		return
	show_condition(order[0])
	(_condition_buttons[order[0]] as Button).grab_focus()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func is_open() -> bool:
	return visible


## Condição mostrada agora.
func current_condition() -> String:
	return _current


## Mostra as referências da condição pedida.
func show_condition(condition_id: String) -> void:
	var condition := SourcesData.get_condition(_data, condition_id)
	if condition.is_empty():
		return
	_current = condition_id
	for id: String in _condition_buttons:
		(_condition_buttons[id] as Button).set_pressed_no_signal(id == condition_id)
	_content.text = build_text(condition)
	_content.scroll_to_line(0)


## Texto (BBCode) com todos os ingredientes de uma condição.
static func build_text(condition: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append(
		(
			"[font_size=%d][color=%s]%s[/color][/font_size]"
			% [HEADING_SIZE, HEADING_COLOR, _escape(condition.get("name", ""))]
		)
	)
	for ingredient: Dictionary in condition.get("ingredients", []):
		parts.append(_ingredient_text(ingredient))
	return "\n\n".join(parts)


static func _ingredient_text(ingredient: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append(
		"[font_size=%d][u]%s[/u][/font_size]" % [HEADING_SIZE - 2, _ingredient_name(ingredient)]
	)
	var summary: String = ingredient.get("summary", "")
	if not summary.is_empty():
		lines.append(_escape(summary))
	var limitations: String = ingredient.get("limitations", "")
	if not limitations.is_empty():
		lines.append(_section_title("Limitações"))
		lines.append(_escape(limitations))
	var references: Array = ingredient.get("references", [])
	if not references.is_empty():
		lines.append(_section_title("Referências bibliográficas"))
		for i in references.size():
			lines.append(_reference_text(i + 1, references[i]))
	return "\n\n".join(lines)


static func _reference_text(number: int, reference: Dictionary) -> String:
	var text := "%d. %s" % [number, _escape(reference.get("text", ""))]
	var url: String = reference.get("url", "")
	if not url.is_empty():
		text += " [url=%s][color=%s]Abrir link[/color][/url]" % [url, LINK_COLOR]
	return text


static func _section_title(title: String) -> String:
	return "[font_size=%d][color=%s]%s[/color][/font_size]" % [SECTION_SIZE, HEADING_COLOR, title]


## Nome do ingrediente como aparece no jogo (do CSV), ou o id se não existir.
static func _ingredient_name(ingredient: Dictionary) -> String:
	var id: String = ingredient.get("id", "")
	var found := IngredientData.get_ingredient(id)
	return _escape(found.display_name if found else id)


## Impede que colchetes do texto sejam lidos como BBCode.
static func _escape(text: String) -> String:
	return text.replace("[", "[lb]")


func _build_condition_buttons() -> void:
	var group := ButtonGroup.new()
	for condition_id in SourcesData.get_condition_order(_data):
		var condition := SourcesData.get_condition(_data, condition_id)
		var button := Button.new()
		button.name = condition_id
		button.text = condition.get("name", condition_id)
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(show_condition.bind(condition_id))
		button.focus_entered.connect(show_condition.bind(condition_id))
		_condition_list.add_child(button)
		_condition_buttons[condition_id] = button


func _on_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	if url.begins_with("https://") or url.begins_with("http://"):
		OS.shell_open(url)
