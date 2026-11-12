class_name MainMenu
extends Control
## Tela inicial do jogo: Novo Jogo, Carregar Jogo, Opções, Créditos e Sair. Funciona com o
## mouse e com o teclado. Carregar Jogo fica desabilitado enquanto não houver
## save.

## Emitido quando o jogador pede para sair do jogo.
signal quit_requested

## Onde o jogo guarda o save (o save em si é a issue #42).
const SAVE_PATH := "user://save.json"

## Arquivo de save procurado. Só muda nos testes.
var save_path := SAVE_PATH

@onready var _new_game_button: Button = $Center/Panel/Layout/NewGameButton
@onready var _load_button: Button = $Center/Panel/Layout/LoadButton
@onready var _options_button: Button = $Center/Panel/Layout/OptionsButton
@onready var _options_menu: OptionsMenu = $OptionsMenu
@onready var _credits_button: Button = $Center/Panel/Layout/CreditsButton
@onready var _quit_button: Button = $Center/Panel/Layout/QuitButton
@onready var _credits_panel: Control = $CreditsPanel
@onready var _credits_back_button: Button = $CreditsPanel/Center/Panel/Layout/BackButton


func _ready() -> void:
	# O menu inicial nunca fica congelado, mesmo vindo do fim da campanha.
	GameState.flow.reset()
	Music.play(Music.MENU)
	_load_button.disabled = not has_save(save_path)
	_credits_panel.hide()
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_options_button.pressed.connect(_options_menu.open)
	_options_menu.closed.connect(_options_button.grab_focus)
	_credits_button.pressed.connect(_credits_panel.show)
	_credits_back_button.pressed.connect(_close_credits)
	_quit_button.pressed.connect(_on_quit_pressed)
	quit_requested.connect(_quit_game)
	_new_game_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _credits_panel.visible and event.is_action_pressed("ui_cancel"):
		_close_credits()
		get_viewport().set_input_as_handled()


## Se existe um save no caminho dado.
static func has_save(path: String = SAVE_PATH) -> bool:
	return FileAccess.file_exists(path)


## Se a tela de Créditos está aberta.
func is_credits_open() -> bool:
	return _credits_panel.visible


func _on_new_game_pressed() -> void:
	GameState.new_game()
	get_tree().change_scene_to_file(ScenePaths.CABIN)


## O carregamento do estado salvo vem com o save (#42); por ora abre a cabana.
func _on_load_pressed() -> void:
	get_tree().change_scene_to_file(ScenePaths.CABIN)


func _on_quit_pressed() -> void:
	quit_requested.emit()


func _quit_game() -> void:
	get_tree().quit()


func _close_credits() -> void:
	_credits_panel.hide()
	_credits_button.grab_focus()
