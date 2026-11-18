class_name SourcesMenu
extends Control
## Tela Fontes, aberta pelo menu inicial: as referências científicas que
## embasam cada ingrediente, separadas por condição, e os créditos de arte e de
## áudio. À esquerda fica a lista de seções; à direita, o conteúdo da escolhida.
## Para cada ingrediente aparecem o resumo, as limitações e as referências, com
## links que abrem no navegador. No topo fica sempre o aviso de que o jogo é
## ficção e não orientação médica (GDD, seção 3).
##
## As referências vêm do data/fontes.json (ver `SourcesData`) e os créditos do
## data/creditos.csv (ver `CreditsData`).

## Emitido quando a tela fecha, para o menu devolver o foco ao botão.
signal closed

const LINK_COLOR := "#7a3b12"
const HEADING_COLOR := "#3b2417"
## Tamanhos dos títulos no texto normal; o "Texto grande" multiplica pelo
## fator do `TextSize`, como faz com o resto do tema.
const HEADING_SIZE := 20
const INGREDIENT_SIZE := 18
const SECTION_SIZE := 16

## Ids das seções de créditos na lista, depois das condições.
const CREDITS_ART := "creditos_arte"
const CREDITS_AUDIO := "creditos_audio"
const CREDITS_TITLES := {
	CREDITS_ART: "Créditos: arte",
	CREDITS_AUDIO: "Créditos: áudio",
}

const DISCLAIMER := (
	"Apotegato é uma obra de ficção. O que o jogo diz sobre plantas e alimentos "
	+ "não é orientação médica: em caso de doença, procure um profissional de saúde."
)

## Arquivo lido. Só muda nos testes.
var data_path := SourcesData.PATH

var _data := {}
var _credits: Array[Dictionary] = []
var _current := ""
var _condition_buttons := {}

@onready var _condition_list: VBoxContainer = %ConditionList
@onready var _condition_scroll: ScrollContainer = %ConditionScroll
@onready var _content: RichTextLabel = %Content
@onready var _back_button: Button = %BackButton
@onready var _disclaimer: Label = %Disclaimer


func _ready() -> void:
	hide()
	_data = SourcesData.load_data(data_path)
	_credits = CreditsData.load_rows()
	_disclaimer.text = DISCLAIMER
	_build_condition_buttons()
	_build_credits_buttons()
	_content.meta_clicked.connect(_on_link_clicked)
	_back_button.pressed.connect(close)
	AudioSettings.changed.connect(_refresh)


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
	# O foco rola a lista antes de o layout assentar; volta ao topo depois.
	_condition_scroll.set_deferred("scroll_vertical", 0)


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func is_open() -> bool:
	return visible


## Seção mostrada agora: o id de uma condição ou de uma seção de créditos.
func current_condition() -> String:
	return _current


## Mostra a seção pedida: as referências de uma condição ou uma das seções de
## créditos (`CREDITS_ART`, `CREDITS_AUDIO`).
func show_condition(section_id: String) -> void:
	var text := ""
	if CREDITS_TITLES.has(section_id):
		var type := CreditsData.ART if section_id == CREDITS_ART else CreditsData.AUDIO
		text = build_credits_text(CREDITS_TITLES[section_id], CreditsData.of_type(_credits, type))
	else:
		var condition := SourcesData.get_condition(_data, section_id)
		if condition.is_empty():
			return
		text = build_text(condition)
	_current = section_id
	for id: String in _condition_buttons:
		(_condition_buttons[id] as Button).set_pressed_no_signal(id == section_id)
	_content.text = text
	_content.scroll_to_line(0)


## Texto (BBCode) com todos os ingredientes de uma condição.
static func build_text(condition: Dictionary) -> String:
	var parts: PackedStringArray = []
	parts.append(
		(
			"[font_size=%d][color=%s]%s[/color][/font_size]"
			% [TextSize.scaled(HEADING_SIZE), HEADING_COLOR, _escape(condition.get("name", ""))]
		)
	)
	for ingredient: Dictionary in condition.get("ingredients", []):
		parts.append(_ingredient_text(ingredient))
	return "\n\n".join(parts)


static func _ingredient_text(ingredient: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append(
		(
			"[font_size=%d][u]%s[/u][/font_size]"
			% [TextSize.scaled(INGREDIENT_SIZE), _ingredient_name(ingredient)]
		)
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


## Texto (BBCode) de uma seção de créditos: cada asset com autor, para que é
## usado no jogo, licença e link da origem.
static func build_credits_text(title: String, rows: Array[Dictionary]) -> String:
	var parts: PackedStringArray = []
	parts.append(
		(
			"[font_size=%d][color=%s]%s[/color][/font_size]"
			% [TextSize.scaled(HEADING_SIZE), HEADING_COLOR, _escape(title)]
		)
	)
	for row in rows:
		var lines: PackedStringArray = []
		lines.append(
			(
				"[font_size=%d][u]%s[/u][/font_size]"
				% [TextSize.scaled(INGREDIENT_SIZE), _escape(row.get("nome", ""))]
			)
		)
		lines.append("Autor: %s" % _escape(row.get("autor", "")))
		lines.append("No jogo: %s" % _escape(row.get("finalidade", "")))
		lines.append("Licença: %s" % _escape(row.get("licenca", "")))
		var url: String = row.get("origem", "")
		if is_web_link(url):
			lines.append("[url=%s][color=%s]Abrir link[/color][/url]" % [url, LINK_COLOR])
		parts.append("\n".join(lines))
	return "\n\n".join(parts)


static func _reference_text(number: int, reference: Dictionary) -> String:
	var text := "%d. %s" % [number, _escape(reference.get("text", ""))]
	var url: String = reference.get("url", "")
	if not url.is_empty():
		text += " [url=%s][color=%s]Abrir link[/color][/url]" % [url, LINK_COLOR]
	return text


static func _section_title(title: String) -> String:
	return (
		"[font_size=%d][color=%s]%s[/color][/font_size]"
		% [TextSize.scaled(SECTION_SIZE), HEADING_COLOR, title]
	)


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


func _build_credits_buttons() -> void:
	var group: ButtonGroup = null
	if _condition_list.get_child_count() > 0:
		group = (_condition_list.get_child(0) as Button).button_group
	_condition_list.add_child(HSeparator.new())
	for section_id: String in [CREDITS_ART, CREDITS_AUDIO]:
		var button := Button.new()
		button.name = section_id
		button.text = CREDITS_TITLES[section_id]
		button.toggle_mode = true
		button.button_group = group
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(show_condition.bind(section_id))
		button.focus_entered.connect(show_condition.bind(section_id))
		_condition_list.add_child(button)
		_condition_buttons[section_id] = button


## Redesenha o texto quando o "Texto grande" muda.
func _refresh() -> void:
	if not _current.is_empty():
		show_condition(_current)


func _on_link_clicked(meta: Variant) -> void:
	var url := str(meta)
	if is_web_link(url):
		OS.shell_open(url)


## Só links da web abrem; outros esquemas (file://, javascript: etc.) são
## ignorados, para um texto do JSON não conseguir abrir arquivos do computador.
static func is_web_link(url: String) -> bool:
	return url.begins_with("https://") or url.begins_with("http://")
