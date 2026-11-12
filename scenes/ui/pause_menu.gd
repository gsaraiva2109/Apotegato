class_name PauseMenu
extends CanvasLayer
## Menu de pausa da cabana e dos andares. Esc (ação `pause`) na exploração
## congela o jogo (estado Menu da máquina de estados) e mostra Continuar,
## Opções e Voltar ao menu inicial. Esc ou Continuar retomam. Não abre no meio
## de um diálogo, de uma entrega ou de outro menu: a máquina de estados recusa
## a transição. Voltar ao menu inicial pede confirmação, porque ainda não há
## save e o progresso se perde.

## Emitido ao abrir a pausa.
signal opened
## Emitido ao retomar o jogo.
signal resumed

const OPTIONS_SCENE := preload("res://scenes/ui/options_menu.tscn")

## Tela de opções, criada só na primeira vez que é aberta (não pesa em cada andar).
var _options: OptionsMenu

@onready var _main_buttons: Control = $Root/Center/Panel/Layout/MainButtons
@onready var _resume_button: Button = $Root/Center/Panel/Layout/MainButtons/ResumeButton
@onready var _options_button: Button = $Root/Center/Panel/Layout/MainButtons/OptionsButton
@onready var _menu_button: Button = $Root/Center/Panel/Layout/MainButtons/MenuButton
@onready var _title: Control = $Root/Center/Panel/Layout/TitlePlank
@onready var _confirm_box: Control = $Root/Center/Panel/Layout/ConfirmBox
@onready var _yes_button: Button = $Root/Center/Panel/Layout/ConfirmBox/YesButton
@onready var _no_button: Button = $Root/Center/Panel/Layout/ConfirmBox/NoButton
@onready var _panel_center: Control = $Root/Center


func _ready() -> void:
	_resume_button.pressed.connect(resume)
	_options_button.pressed.connect(_open_options)
	_menu_button.pressed.connect(_ask_to_leave)
	_yes_button.pressed.connect(_leave_to_main_menu)
	_no_button.pressed.connect(_cancel_leave)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or event.is_echo():
		return
	if not visible:
		if pause():
			get_viewport().set_input_as_handled()
	elif _confirm_box.visible:
		_cancel_leave()
		get_viewport().set_input_as_handled()
	elif _options == null or not _options.is_open():
		resume()
		get_viewport().set_input_as_handled()


## Pausa o jogo. Devolve false (e não faz nada) se o jogo não está na
## exploração: diálogo, entrega e menus abertos recusam a pausa.
func pause() -> bool:
	if visible or not GameState.flow.open_menu():
		return false
	_show_main()
	visible = true
	_resume_button.grab_focus()
	opened.emit()
	return true


## Retoma o jogo.
func resume() -> void:
	if not visible:
		return
	visible = false
	if _options != null:
		_options.close()
	GameState.flow.close_menu()
	resumed.emit()


func is_open() -> bool:
	return visible


func _show_main() -> void:
	_title.show()
	_main_buttons.show()
	_confirm_box.hide()
	_panel_center.show()


func _open_options() -> void:
	if _options == null:
		_options = OPTIONS_SCENE.instantiate()
		add_child(_options)
		_options.closed.connect(_on_options_closed)
	_panel_center.hide()
	_options.open()


func _on_options_closed() -> void:
	if not visible:
		return
	_panel_center.show()
	_options_button.grab_focus()


func _ask_to_leave() -> void:
	_title.hide()
	_main_buttons.hide()
	_confirm_box.show()
	_no_button.grab_focus()


func _cancel_leave() -> void:
	_show_main()
	_menu_button.grab_focus()


func _leave_to_main_menu() -> void:
	visible = false
	GameState.flow.close_menu()
	get_tree().change_scene_to_file(ScenePaths.MENU)
