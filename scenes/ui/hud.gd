class_name Hud
extends CanvasLayer
## Interface da exploração: os corações (canto superior esquerdo, como em
## Zelda), região e andar, o contador da mochila e os avisos rápidos ("Pegou
## Buriti", "Mochila cheia").

const HEART_FULL := preload("res://assets/art/ui/heart_full.png")
const HEART_EMPTY := preload("res://assets/art/ui/heart_empty.png")
const HEART_SIZE := Vector2(36, 30)

## Quanto tempo um aviso fica na tela, em segundos.
const MESSAGE_SECONDS := 2.5

@onready var _hearts_box: HBoxContainer = $Root/HeartsBox
@onready var _location_label: Label = $Root/LocationPanel/LocationLabel
@onready var _backpack_label: Label = $Root/BackpackPanel/BackpackLabel
@onready var _message_label: Label = $Root/MessageLabel
@onready var _message_timer: Timer = $MessageTimer


func _ready() -> void:
	_message_timer.wait_time = MESSAGE_SECONDS
	_message_timer.timeout.connect(_message_label.hide)
	_message_label.hide()


## Mostra os corações: `current` cheios e o resto vazios, até `maximum`.
func show_hearts(current: int, maximum: int) -> void:
	while _hearts_box.get_child_count() > maximum:
		var extra := _hearts_box.get_child(_hearts_box.get_child_count() - 1)
		_hearts_box.remove_child(extra)
		extra.queue_free()
	while _hearts_box.get_child_count() < maximum:
		_hearts_box.add_child(_new_heart())
	for i in maximum:
		(_hearts_box.get_child(i) as TextureRect).texture = (
			HEART_FULL if i < current else HEART_EMPTY
		)


## Quantos corações cheios estão na tela.
func full_hearts() -> int:
	var full := 0
	for heart: TextureRect in _hearts_box.get_children():
		if heart.texture == HEART_FULL:
			full += 1
	return full


## Mostra a região e o andar, como "Amazônia - Andar 2".
func show_location(region: String, floor_number: int) -> void:
	_location_label.text = location_text(region, floor_number)


## Mostra o contador da mochila: espaços usados e o que já foi coletado.
func show_backpack(backpack: Backpack) -> void:
	_backpack_label.text = backpack_text(backpack)


## Mostra um aviso por alguns segundos.
func show_message(text: String) -> void:
	_message_label.text = text
	_message_label.show()
	_message_timer.start()


## Texto da região e do andar. Fica separado para ser testado.
static func location_text(region: String, floor_number: int) -> String:
	return "%s - Andar %d" % [Regions.display_name(region), floor_number]


## Texto do contador da mochila, uma linha por ingrediente, com os nomes do CSV.
static func backpack_text(backpack: Backpack) -> String:
	var lines: Array[String] = ["Mochila %d/%d" % [backpack.used_slots(), Backpack.MAX_SLOTS]]
	for id in backpack.ids():
		var ingredient := IngredientData.get_ingredient(id)
		var item_name := ingredient.display_name if ingredient != null else id
		lines.append("%s x%d" % [item_name, backpack.count(id)])
	return "\n".join(lines)


func _new_heart() -> TextureRect:
	var heart := TextureRect.new()
	heart.custom_minimum_size = HEART_SIZE
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return heart
