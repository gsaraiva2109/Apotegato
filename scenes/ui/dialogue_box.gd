class_name DialogueBox
extends CanvasLayer
## Caixa de diálogo na parte de baixo da tela, com o nome de quem fala numa
## tábua e o texto aparecendo letra por letra. E (ação `interact`), Enter ou
## clique completam a fala; o aperto seguinte passa para a próxima. Falas
## longas são divididas em páginas que cabem no painel.
##
## Quando a última fala tem escolhas, aparecem botões (mouse, setas e E) e a
## caixa termina com o id da opção escolhida.
##
## A caixa não decide o estado do jogo: quem abre a conversa escuta `finished`
## e decide o que vem depois. Enquanto está aberta, ela fica por cima de tudo e
## segura o teclado e o mouse, para nada embaixo reagir.

## Emitido quando uma fala começa a aparecer (índice na lista de `play`).
signal line_started(index: int)
## Emitido quando a conversa termina. `choice` é o id da opção escolhida, ou ""
## se a conversa não tinha escolha. A caixa já se fechou.
signal finished(choice: String)

## Letras por segundo do texto aparecendo. 0 mostra a fala inteira de uma vez.
@export var characters_per_second := 60.0
## Linhas de texto por página.
@export var max_lines := 4

## Uma página por item: {"line": índice da fala, "name": nome, "text": texto}.
var _pages: Array[Dictionary] = []
var _lines: Array[DialogueLine] = []
var _page := 0
var _shown_characters := 0.0
var _open := false

@onready var _text: Label = $Root/Text
@onready var _name_label: Label = $Root/NamePlate/NameLabel
@onready var _name_plate: Control = $Root/NamePlate
@onready var _choices: HBoxContainer = $Root/Choices
@onready var _next_hint: Label = $Root/NextHint


func _process(delta: float) -> void:
	if not _open or is_page_complete():
		return
	_shown_characters += characters_per_second * delta
	_text.visible_characters = int(_shown_characters)
	if is_page_complete():
		_on_page_complete()


func _input(event: InputEvent) -> void:
	if not _open:
		return
	# Tela cheia e escala da janela continuam funcionando durante a conversa.
	if event.is_action("toggle_fullscreen") or event.is_action("toggle_scale_mode"):
		return
	if is_choosing():
		_handle_choice_input(event)
		return
	if (
		event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
		or _is_left_click(event)
	):
		advance()
	# Teclas e cliques não passam para baixo da caixa; só o movimento do mouse.
	if not event is InputEventMouseMotion:
		get_viewport().set_input_as_handled()


## Mostra a conversa desde a primeira fala. `values` troca marcadores no texto,
## como {"missing": "Mel e Pequi"} para "{missing}".
func play(lines: Array[DialogueLine], values: Dictionary = {}) -> void:
	_lines = lines
	_open = true
	visible = true
	_pages.clear()
	for index in lines.size():
		var text := lines[index].text
		if not values.is_empty():
			text = text.format(values)
		for page_text in paginate(text):
			_pages.append({"line": index, "name": lines[index].speaker_name, "text": page_text})
	if _pages.is_empty():
		_close("")
		return
	_show_page(0)


## Completa a página que está aparecendo ou passa para a próxima. Na última
## página, fecha a conversa (a não ser que ela tenha escolhas).
func advance() -> void:
	if not _open or is_choosing():
		return
	if not is_page_complete():
		_text.visible_characters = -1
		_on_page_complete()
		return
	if _page + 1 < _pages.size():
		_show_page(_page + 1)
	elif not _current_line().has_choices():
		_close("")


## Escolhe uma opção (pelo id). Só funciona com as escolhas na tela.
func choose(choice_id: String) -> void:
	if is_choosing():
		_close(choice_id)


func is_open() -> bool:
	return _open


## Se as escolhas estão na tela esperando o jogador.
func is_choosing() -> bool:
	return _open and _choices.visible


## Se a página atual já apareceu inteira.
func is_page_complete() -> bool:
	return _text.visible_characters < 0 or _text.visible_characters >= _text.text.length()


## Nome de quem fala na página atual.
func current_speaker() -> String:
	return _name_label.text


## Texto completo da página atual (mesmo que ainda esteja aparecendo).
func current_text() -> String:
	return _text.text


func page_count() -> int:
	return _pages.size()


func current_page() -> int:
	return _page


## Botões das escolhas, na ordem.
func choice_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child in _choices.get_children():
		if child is Button and not child.is_queued_for_deletion():
			buttons.append(child)
	return buttons


## Divide o texto em páginas de até `max_lines` linhas na largura da caixa,
## quebrando entre palavras.
func paginate(text: String) -> PackedStringArray:
	var pages := PackedStringArray()
	var current := ""
	for word in text.split(" ", false):
		var candidate := word if current.is_empty() else current + " " + word
		if not current.is_empty() and _line_count(candidate) > max_lines:
			pages.append(current)
			current = word
		else:
			current = candidate
	if not current.is_empty():
		pages.append(current)
	return pages


func _line_count(text: String) -> int:
	var font := _text.get_theme_font("font")
	var font_size := _text.get_theme_font_size("font_size")
	var size := font.get_multiline_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, _text.size.x, font_size
	)
	return ceili(size.y / font.get_height(font_size) - 0.01)


func _show_page(index: int) -> void:
	var previous_line: int = _pages[_page]["line"] if _page < _pages.size() else -1
	_page = index
	var page: Dictionary = _pages[index]
	_name_label.text = page["name"]
	_name_plate.visible = not str(page["name"]).is_empty()
	_text.text = page["text"]
	_clear_choices()
	_next_hint.visible = false
	if characters_per_second <= 0.0:
		_text.visible_characters = -1
	else:
		_shown_characters = 0.0
		_text.visible_characters = 0
	if index == 0 or page["line"] != previous_line:
		line_started.emit(page["line"])
	if is_page_complete():
		_on_page_complete()


func _on_page_complete() -> void:
	_text.visible_characters = -1
	var last_page := _page == _pages.size() - 1
	if last_page and _current_line().has_choices():
		_show_choices(_current_line().choices)
	else:
		_next_hint.visible = true


func _current_line() -> DialogueLine:
	return _lines[_pages[_page]["line"]]


func _show_choices(choices: Array[Dictionary]) -> void:
	_clear_choices()
	for choice in choices:
		var button := Button.new()
		button.name = "%sButton" % str(choice["id"]).to_pascal_case()
		button.text = choice["text"]
		button.pressed.connect(choose.bind(choice["id"]))
		_choices.add_child(button)
	var buttons := choice_buttons()
	# O foco fica preso nas escolhas: nada embaixo da caixa recebe as setas.
	for i in buttons.size():
		var left := buttons[i - 1] if i > 0 else buttons[i]
		var right := buttons[i + 1] if i + 1 < buttons.size() else buttons[i]
		buttons[i].focus_neighbor_left = buttons[i].get_path_to(left)
		buttons[i].focus_neighbor_right = buttons[i].get_path_to(right)
		buttons[i].focus_neighbor_top = buttons[i].get_path_to(buttons[i])
		buttons[i].focus_neighbor_bottom = buttons[i].get_path_to(buttons[i])
	_choices.visible = true
	buttons[0].grab_focus()


func _clear_choices() -> void:
	_choices.visible = false
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()


## Com as escolhas na tela, E confirma a opção em foco; as setas e o mouse
## chegam aos botões normalmente. Esc não fecha: a escolha é obrigatória.
func _handle_choice_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var focused := _choices.get_viewport().gui_get_focus_owner() as Button
		if focused != null and focused.get_parent() == _choices:
			focused.pressed.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()


func _close(choice: String) -> void:
	_open = false
	visible = false
	_clear_choices()
	finished.emit(choice)


func _is_left_click(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT
