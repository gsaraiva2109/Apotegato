extends Node
## Adapta a janela do jogo ao monitor de quem joga, qualquer que seja a
## resolução: o jogo continua sendo desenhado em 960 x 544 e só a ampliação
## muda (a conta fica em `scripts/window_scale.gd`).
##
## - Ao abrir, a janela ganha o maior tamanho que cabe na parte livre do monitor
##   (sem a barra de tarefas) e fica centralizada.
## - Pixel perfeito (padrão): amplia só por números inteiros, sem deformar os
##   pixels; pode sobrar borda preta. Preencher a tela: usa a maior escala que
##   cabe. Em telas menores que 960 x 544 os dois modos reduzem a imagem.
## - F11 alterna a tela cheia e F10 alterna o modo de escala (ações
##   `toggle_fullscreen` e `toggle_scale_mode`), inclusive com o jogo pausado.
## - As duas escolhas ficam salvas em `user://settings.cfg`.
##
## Sem janela (testes e CI em modo headless) e com o jogo embutido na aba Game
## do editor, não mexe no tamanho nem na posição da janela.
##
## Registrado como autoload "DisplaySettings". Usa `preload` em vez do
## `class_name` porque o autoload é lido antes de o Godot registrar as classes.

## Emitido quando a ampliação do jogo muda (janela redimensionada, tela cheia
## ou troca de modo). O cursor usa para acompanhar o tamanho dos pixels.
signal scale_changed(content_scale: float)

const Scale := preload("res://scripts/window_scale.gd")

## Arquivo das opções do jogo (separado do save da campanha).
const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "display"
## Menor tamanho a que a janela pode ser reduzida, em fração da resolução do jogo.
const MIN_WINDOW_FRACTION := 0.5

## Arquivo de opções lido e gravado. Só muda nos testes.
var settings_path := SETTINGS_PATH
## Se o jogo está (ou deve abrir) em tela cheia.
var fullscreen := false
## Modo pixel perfeito (escala inteira) ligado; desligado, preenche a tela.
var pixel_perfect := true
## Ampliação em uso agora (2.0 = cada pixel do jogo ocupa 2 x 2 na tela).
var current_scale := 1.0

## Resolução em que o jogo é desenhado, lida do project.godot.
var _base := Vector2i(960, 544)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_base = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	load_settings()
	var window := get_window()
	window.size_changed.connect(apply_scale)
	if controls_window():
		window.min_size = Vector2i(Vector2(_base) * MIN_WINDOW_FRACTION)
		if fullscreen:
			window.mode = Window.MODE_FULLSCREEN
		else:
			fit_window()
	apply_scale()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		set_fullscreen(not fullscreen)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_scale_mode"):
		set_pixel_perfect(not pixel_perfect)
		get_viewport().set_input_as_handled()


## Se este processo pode mudar o tamanho e o modo da janela.
func controls_window() -> bool:
	return DisplayServer.get_name() != "headless" and not Engine.is_embedded_in_editor()


## Liga ou desliga a tela cheia e salva a escolha. Ao sair dela, a janela volta
## ao maior tamanho que cabe no monitor.
func set_fullscreen(value: bool) -> void:
	fullscreen = value
	save_settings()
	if controls_window():
		if value:
			get_window().mode = Window.MODE_FULLSCREEN
		else:
			get_window().mode = Window.MODE_WINDOWED
			# A janela só aceita o tamanho novo depois de sair da tela cheia.
			fit_window.call_deferred()
	apply_scale()


## Liga o modo pixel perfeito (true) ou o preencher a tela (false) e salva a
## escolha. Em janela, ela é refeita para o tamanho do modo novo.
func set_pixel_perfect(value: bool) -> void:
	pixel_perfect = value
	save_settings()
	if controls_window() and get_window().mode == Window.MODE_WINDOWED:
		fit_window()
	apply_scale()


## Dá à janela o maior tamanho do modo atual que cabe na parte livre do monitor
## em que ela está, descontando a barra de título, e a centraliza.
func fit_window() -> void:
	if not controls_window() or fullscreen:
		return
	var window := get_window()
	window.mode = Window.MODE_WINDOWED
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var decorations := window.get_size_with_decorations() - window.size
	var size := Scale.window_size(usable.size - decorations, _base, pixel_perfect)
	window.size = size
	# No Wayland o compositor decide onde a janela fica e ignora a posição.
	window.position = Scale.centered_position(usable, size + decorations)


## Aplica o modo de escala ao tamanho atual da janela e avisa se a ampliação
## mudou. A escala inteira só vale quando a janela comporta o jogo em 1x; numa
## janela menor ela cortaria a imagem, então o jogo é reduzido até caber.
func apply_scale() -> void:
	var window := get_window()
	if Scale.uses_integer(window.size, _base, pixel_perfect):
		window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_INTEGER
	else:
		window.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL
	var new_scale := Scale.content_scale(window.size, _base, pixel_perfect)
	if not is_equal_approx(new_scale, current_scale):
		current_scale = new_scale
		scale_changed.emit(current_scale)


## Lê as escolhas salvas. Sem arquivo, fica no padrão: janela e pixel perfeito.
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	fullscreen = bool(config.get_value(SECTION, "fullscreen", false))
	pixel_perfect = bool(config.get_value(SECTION, "pixel_perfect", true))


## Grava as escolhas, mantendo as outras seções do arquivo (ex.: volumes, #96).
func save_settings() -> void:
	var config := ConfigFile.new()
	config.load(settings_path)
	config.set_value(SECTION, "fullscreen", fullscreen)
	config.set_value(SECTION, "pixel_perfect", pixel_perfect)
	config.save(settings_path)
