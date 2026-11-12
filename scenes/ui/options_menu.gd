class_name OptionsMenu
extends CanvasLayer
## Tela de opções, aberta pelo menu inicial e pelo menu de pausa. Três abas:
## Som (volume da música e dos efeitos e o mudo de cada um), Vídeo (tela cheia
## e escala, os mesmos do F11 e do F10) e Acessibilidade (reduzir efeitos
## visuais). Cada escolha vale na hora e fica salva (`AudioSettings` e
## `DisplaySettings`). Funciona com mouse e teclado; todo interruptor mostra o
## estado em texto, além da imagem. Esc ou Voltar fecham só esta tela.

## Emitido sempre que a tela se fecha.
signal closed

enum Tab { SOUND, VIDEO, ACCESSIBILITY }

const ICON_SOUND := preload("res://assets/art/ui/icon_sound.png")
const ICON_MUTE := preload("res://assets/art/ui/icon_mute.png")
const TEXT_ON := "Ligado"
const TEXT_OFF := "Desligado"
const _LAYOUT := "Root/Center/Panel/Layout/"

var _music_dragging := false
var _sfx_dragging := false

@onready var _tab_buttons: Array[Button] = [
	get_node(_LAYOUT + "Tabs/SoundTab"),
	get_node(_LAYOUT + "Tabs/VideoTab"),
	get_node(_LAYOUT + "Tabs/AccessTab"),
]
@onready var _pages: Array[Control] = [
	get_node(_LAYOUT + "Pages/SoundPage"),
	get_node(_LAYOUT + "Pages/VideoPage"),
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
@onready
var _reduce_switch: CheckButton = get_node(_LAYOUT + "Pages/AccessPage/ReduceRow/ReduceSwitch")
@onready var _reduce_state: Label = get_node(_LAYOUT + "Pages/AccessPage/ReduceRow/ReduceState")
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
	AudioSettings.changed.connect(refresh)
	_reset_button.pressed.connect(AudioSettings.reset_to_defaults)
	_back_button.pressed.connect(close)
	set_process(false)
	refresh()


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
	AudioSettings.save_settings()
	visible = false
	set_process(false)
	closed.emit()


func is_open() -> bool:
	return visible


## Mostra a aba pedida e esconde as outras.
func show_tab(tab: int) -> void:
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
	_sync_video_switches()


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
