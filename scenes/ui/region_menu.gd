class_name RegionMenu
extends CanvasLayer
## Menu de escolha de região: uma opção para cada uma das seis, com o nome e um
## ícone (o tile de chão da região). Serve à porta da cabana e ao menu da porta
## do andar. Funciona com o mouse e com o teclado, e Esc fecha.

## Emitido quando o jogador escolhe uma região. O menu já se fechou.
signal region_selected(region: String)
## Emitido sempre que o menu se fecha, com ou sem escolha.
signal closed

## Parte do tileset usada como ícone: o primeiro tile (chão).
const ICON_REGION := Rect2(0, 0, 32, 32)
const BUTTON_SIZE := Vector2(260, 44)

## region id -> botão.
var _buttons: Dictionary = {}

@onready var _regions: VBoxContainer = $Root/Center/Panel/Layout/Regions
@onready var _back_button: Button = $Root/Center/Panel/Layout/BackButton


func _ready() -> void:
	for region in Regions.IDS:
		_add_button(region)
	_back_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Abre o menu. A região em `excluded_region` (se houver) não aparece: é o caso
## de "ir para outra região".
func open(excluded_region: String = "") -> void:
	var first: Button = null
	for region: String in _buttons:
		var button: Button = _buttons[region]
		button.visible = region != excluded_region
		if button.visible and first == null:
			first = button
	visible = true
	first.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


## Botão de uma região (para os testes e para quem quiser focar um deles).
func get_button(region: String) -> Button:
	return _buttons[region]


func _add_button(region: String) -> void:
	var icon := AtlasTexture.new()
	icon.atlas = load(Regions.tileset_path(region))
	icon.region = ICON_REGION
	var button := Button.new()
	button.name = "%sButton" % region.to_pascal_case()
	button.text = Regions.display_name(region)
	button.icon = icon
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = BUTTON_SIZE
	button.pressed.connect(_on_region_pressed.bind(region))
	_regions.add_child(button)
	_buttons[region] = button


func _on_region_pressed(region: String) -> void:
	close()
	region_selected.emit(region)
