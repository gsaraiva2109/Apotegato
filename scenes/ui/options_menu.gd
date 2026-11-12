class_name OptionsMenu
extends CanvasLayer
## Tela de opções, aberta pelo menu inicial e pelo menu de pausa. Quatro abas:
## Som (volume da música e dos efeitos e o mudo de cada um), Vídeo (tela cheia
## e escala, os mesmos do F11 e do F10), Teclas (trocar as teclas do jogo) e
## Acessibilidade (reduzir efeitos visuais e texto grande). Cada escolha vale
## na hora e fica salva (`AudioSettings`, `DisplaySettings` e `InputSettings`).
## Funciona com mouse e teclado; todo interruptor mostra o estado em texto,
## além da imagem. Esc ou Voltar fecham só esta tela.

## Emitido sempre que a tela se fecha.
signal closed

enum Tab { SOUND, VIDEO, KEYS, ACCESSIBILITY }

const ICON_SOUND := preload("res://assets/art/ui/icon_sound.png")
const ICON_MUTE := preload("res://assets/art/ui/icon_mute.png")
const TEXT_ON := "Ligado"
const TEXT_OFF := "Desligado"
const KEYS_HINT := "Clique numa tecla e aperte a nova. Esc cancela; Delete limpa a alternativa."
const _LAYOUT := "Root/Center/Panel/Layout/"
const _ACCESS := "Root/Center/Panel/Layout/Pages/AccessPage/"

var _music_dragging := false
var _sfx_dragging := false
## Posição de tecla esperando uma tecla nova: ação e posição (vazia fora disso).
var _capture_action := &""
var _capture_slot := -1
## Botão de cada posição de tecla, por "ação/posição".
var _key_buttons := {}

@onready var _tab_buttons: Array[Button] = [
	get_node(_LAYOUT + "Tabs/SoundTab"),
	get_node(_LAYOUT + "Tabs/VideoTab"),
	get_node(_LAYOUT + "Tabs/KeysTab"),
	get_node(_LAYOUT + "Tabs/AccessTab"),
]
@onready var _pages: Array[Control] = [
	get_node(_LAYOUT + "Pages/SoundPage"),
	get_node(_LAYOUT + "Pages/VideoPage"),
	get_node(_LAYOUT + "Pages/KeysPage"),
	get_node(_LAYOUT + "Pages/AccessPage"),
]
@onready var _music_slider: HSlider = get_node(_LAYOUT + "Pages/SoundPage/MusicRow/MusicSlider")
@onready var _music_value: Label = get_node(_LAYOUT + "Pages/SoundPage/MusicRow/MusicValue")
@onready var _music_icon: TextureRect = get_node(_LAYOUT + "Pages/SoundPage/MusicRow/MusicIcon")
@onready
var _music_mute: CheckButton = get_node(_LAYOUT + "Pages/SoundPage/MusicMuteRow/MusicMuteSwitch")
@onready
var _music_mute_state: Label = get_node(_LAYOUT + "Pages/SoundPage/MusicMuteRow/MusicMuteState")
@onready var _sfx_slider: HSlider = get_node(_LAYOUT + "Pages/SoundPage/SfxRow/SfxSlider")
@onready var _sfx_value: Label = get_node(_LAYOUT + "Pages/SoundPage/SfxRow/SfxValue")
@onready var _sfx_icon: TextureRect = get_node(_LAYOUT + "Pages/SoundPage/SfxRow/SfxIcon")
@onready var _sfx_mute: CheckButton = get_node(_LAYOUT + "Pages/SoundPage/SfxMuteRow/SfxMuteSwitch")
@onready var _sfx_mute_state: Label = get_node(_LAYOUT + "Pages/SoundPage/SfxMuteRow/SfxMuteState")
@onready var _fullscreen_switch: CheckButton = get_node(
	_LAYOUT + "Pages/VideoPage/FullscreenRow/FullscreenSwitch"
)
@onready
var _fullscreen_state: Label = get_node(_LAYOUT + "Pages/VideoPage/FullscreenRow/FullscreenState")
@onready var _pixel_switch: CheckButton = get_node(_LAYOUT + "Pages/VideoPage/PixelRow/PixelSwitch")
@onready var _pixel_state: Label = get_node(_LAYOUT + "Pages/VideoPage/PixelRow/PixelState")
@onready var _reduce_switch: CheckButton = get_node(_ACCESS + "ReduceRow/ReduceSwitch")
@onready var _reduce_state: Label = get_node(_ACCESS + "ReduceRow/ReduceState")
@onready var _large_switch: CheckButton = get_node(_ACCESS + "LargeTextRow/LargeTextSwitch")
@onready var _large_state: Label = get_node(_ACCESS + "LargeTextRow/LargeTextState")
@onready var _keys_grid: GridContainer = get_node(_LAYOUT + "Pages/KeysPage/Grid")
@onready var _keys_status: Label = get_node(_LAYOUT + "Pages/KeysPage/KeysStatus")
@onready var _reset_button: Button = get_node(_LAYOUT + "Footer/ResetButton")
@onready var _back_button: Button = get_node(_LAYOUT + "Footer/BackButton")


func _ready() -> void:
	var group := ButtonGroup.new()
	for i in _tab_buttons.size():
		_tab_buttons[i].button_group = group
		_tab_buttons[i].pressed.connect(show_tab.bind(i))
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_music_slider.drag_started.connect(func() -> void: _music_dragging = true)
	_sfx_slider.drag_started.connect(func() -> void: _sfx_dragging = true)
	_music_slider.drag_ended.connect(_on_music_drag_ended)
	_sfx_slider.drag_ended.connect(_on_sfx_drag_ended)
	_music_mute.toggled.connect(AudioSettings.set_music_muted)
	_sfx_mute.toggled.connect(AudioSettings.set_sfx_muted)
	_fullscreen_switch.toggled.connect(_on_fullscreen_toggled)
	_pixel_switch.toggled.connect(_on_pixel_toggled)
	_reduce_switch.toggled.connect(AudioSettings.set_reduce_effects)
	_large_switch.toggled.connect(AudioSettings.set_large_text)
	_build_key_buttons()
	InputSettings.bindings_changed.connect(_refresh_keys)
	AudioSettings.changed.connect(refresh)
	_reset_button.pressed.connect(reset_all)
	_back_button.pressed.connect(close)
	set_process(false)
	refresh()


## Enquanto uma tecla espera a nova, o próximo apertar de tecla vira a escolha
## (antes de a interface tratar a tecla). Esc cancela e Delete limpa a alternativa.
func _input(event: InputEvent) -> void:
	if not is_capturing() or not InputSettings.is_key_press(event):
		return
	get_viewport().set_input_as_handled()
	var code := InputSettings.keycode_of(event)
	if InputSettings.is_cancel_key(code):
		cancel_capture()
	elif InputSettings.is_clear_key(code):
		_clear_captured()
	else:
		_assign_captured(code)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## F10 e F11 mudam o vídeo sem passar por aqui; enquanto a tela está aberta, os
## interruptores de vídeo acompanham.
func _process(_delta: float) -> void:
	_sync_video_switches()


## Abre a tela na aba Som, com o foco nela (teclado e controle funcionam logo).
func open() -> void:
	refresh()
	show_tab(Tab.SOUND)
	visible = true
	set_process(true)
	_tab_buttons[Tab.SOUND].grab_focus()


## Salva e fecha. Quem abriu volta a mostrar a própria tela.
func close() -> void:
	if not visible:
		return
	cancel_capture()
	AudioSettings.save_settings()
	visible = false
	set_process(false)
	closed.emit()


func is_open() -> bool:
	return visible


## Mostra a aba pedida e esconde as outras.
func show_tab(tab: int) -> void:
	cancel_capture()
	for i in _pages.size():
		_pages[i].visible = i == tab
		_tab_buttons[i].set_pressed_no_signal(i == tab)


## Aba visível agora.
func current_tab() -> int:
	for i in _pages.size():
		if _pages[i].visible:
			return i
	return Tab.SOUND


## Atualiza todos os controles com as opções atuais, sem disparar mudanças.
func refresh() -> void:
	_music_slider.set_value_no_signal(AudioSettings.music_volume)
	_sfx_slider.set_value_no_signal(AudioSettings.sfx_volume)
	_music_mute.set_pressed_no_signal(AudioSettings.music_muted)
	_sfx_mute.set_pressed_no_signal(AudioSettings.sfx_muted)
	_reduce_switch.set_pressed_no_signal(AudioSettings.reduce_effects)
	_music_value.text = _percent_text(AudioSettings.music_volume, AudioSettings.music_muted)
	_sfx_value.text = _percent_text(AudioSettings.sfx_volume, AudioSettings.sfx_muted)
	_music_icon.texture = _icon_for(AudioSettings.music_volume, AudioSettings.music_muted)
	_sfx_icon.texture = _icon_for(AudioSettings.sfx_volume, AudioSettings.sfx_muted)
	_music_mute_state.text = _state_text(AudioSettings.music_muted)
	_sfx_mute_state.text = _state_text(AudioSettings.sfx_muted)
	_reduce_state.text = _state_text(AudioSettings.reduce_effects)
	_large_switch.set_pressed_no_signal(AudioSettings.large_text)
	_large_state.text = _state_text(AudioSettings.large_text)
	_refresh_keys()
	_sync_video_switches()


## Volta som, acessibilidade, vídeo e teclas ao padrão.
func reset_all() -> void:
	cancel_capture()
	InputSettings.reset_to_defaults()
	DisplaySettings.set_fullscreen(false)
	DisplaySettings.set_pixel_perfect(true)
	AudioSettings.reset_to_defaults()


## Se alguma posição de tecla espera uma tecla nova.
func is_capturing() -> bool:
	return _capture_action != &""


## Passa a esperar a tecla nova da posição (um segundo pedido na mesma posição
## cancela).
func start_capture(action: StringName, slot: int) -> void:
	if _capture_action == action and _capture_slot == slot:
		cancel_capture()
		return
	_capture_action = action
	_capture_slot = slot
	_keys_status.text = (
		'Aperte a nova tecla para "%s". Esc cancela.' % InputSettings.ACTION_LABELS[action]
	)
	_refresh_keys()


func cancel_capture() -> void:
	if not is_capturing():
		return
	_capture_action = &""
	_capture_slot = -1
	_keys_status.text = KEYS_HINT
	_refresh_keys()


## Botão da posição de tecla (para a tela e para os testes).
func key_button(action: StringName, slot: int) -> Button:
	return _key_buttons["%s/%d" % [action, slot]]


func _assign_captured(code: int) -> void:
	var action := _capture_action
	var slot := _capture_slot
	var owner_name := InputSettings.owner_of(code, action, slot)
	var result := InputSettings.set_key(action, slot, code)
	var label := InputSettings.key_label(code)
	_capture_action = &""
	_capture_slot = -1
	match result:
		InputSettings.Result.OK:
			_keys_status.text = '"%s" agora usa %s.' % [InputSettings.ACTION_LABELS[action], label]
		InputSettings.Result.TAKEN:
			_keys_status.text = (
				'%s já é de "%s". Escolha outra tecla.'
				% [label, InputSettings.ACTION_LABELS[owner_name]]
			)
		InputSettings.Result.RESERVED_KEY:
			_keys_status.text = (
				'%s é reservada para "%s". Escolha outra tecla.'
				% [label, InputSettings.ACTION_LABELS[owner_name]]
			)
		_:
			_keys_status.text = KEYS_HINT
	_refresh_keys()


func _clear_captured() -> void:
	var action := _capture_action
	var slot := _capture_slot
	_capture_action = &""
	_capture_slot = -1
	if InputSettings.clear_slot(action, slot):
		_keys_status.text = 'Tecla de "%s" removida.' % InputSettings.ACTION_LABELS[action]
	else:
		_keys_status.text = (
			'"%s" precisa de pelo menos uma tecla.' % InputSettings.ACTION_LABELS[action]
		)
	_refresh_keys()


## Monta a grade: movimentos à esquerda, ações à direita, cada um com a tecla
## principal e a alternativa.
func _build_key_buttons() -> void:
	for header in ["", "Principal", "Alternativa", "", "Principal", "Alternativa"]:
		var label := Label.new()
		label.text = header
		label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		_keys_grid.add_child(label)
	var movement: Array[StringName] = [&"move_up", &"move_down", &"move_left", &"move_right"]
	var actions: Array[StringName] = [&"attack", &"interact", &"backpack", &"journal"]
	for row in movement.size():
		for action in [movement[row], actions[row]]:
			var name_label := Label.new()
			name_label.text = InputSettings.ACTION_LABELS[action]
			name_label.custom_minimum_size = Vector2(130, 0)
			_keys_grid.add_child(name_label)
			for slot in InputSettings.SLOTS:
				var button := Button.new()
				button.custom_minimum_size = Vector2(100, 0)
				button.pressed.connect(start_capture.bind(action, slot))
				_keys_grid.add_child(button)
				_key_buttons["%s/%d" % [action, slot]] = button


func _refresh_keys() -> void:
	for action in InputSettings.REMAPPABLE:
		for slot in InputSettings.SLOTS:
			var button: Button = _key_buttons.get("%s/%d" % [action, slot])
			if button == null:
				continue
			if action == _capture_action and slot == _capture_slot:
				button.text = "Aperte..."
			else:
				button.text = InputSettings.key_label(InputSettings.key_in_slot(action, slot))


func _sync_video_switches() -> void:
	_fullscreen_switch.set_pressed_no_signal(DisplaySettings.fullscreen)
	_pixel_switch.set_pressed_no_signal(DisplaySettings.pixel_perfect)
	_fullscreen_state.text = _state_text(DisplaySettings.fullscreen)
	_pixel_state.text = _state_text(DisplaySettings.pixel_perfect)


func _on_fullscreen_toggled(value: bool) -> void:
	DisplaySettings.set_fullscreen(value)
	_sync_video_switches()


func _on_pixel_toggled(value: bool) -> void:
	DisplaySettings.set_pixel_perfect(value)
	_sync_video_switches()


func _on_music_changed(value: float) -> void:
	AudioSettings.set_music_volume(int(value), not _music_dragging)


func _on_sfx_changed(value: float) -> void:
	AudioSettings.set_sfx_volume(int(value), not _sfx_dragging)


func _on_music_drag_ended(_changed: bool) -> void:
	_music_dragging = false
	AudioSettings.save_settings()


func _on_sfx_drag_ended(_changed: bool) -> void:
	_sfx_dragging = false
	AudioSettings.save_settings()


## "70%", ou "Mudo" quando o canal está silenciado (texto, não só ícone ou cor).
static func _percent_text(percent: int, muted: bool) -> String:
	return "Mudo" if muted else "%d%%" % percent


static func _state_text(on: bool) -> String:
	return TEXT_ON if on else TEXT_OFF


static func _icon_for(percent: int, muted: bool) -> Texture2D:
	return ICON_MUTE if muted or percent == 0 else ICON_SOUND
