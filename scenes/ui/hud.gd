class_name Hud
extends CanvasLayer
## Interface da exploração: os corações (canto superior esquerdo, como em
## Zelda), região e andar, o contador da mochila e os avisos rápidos ("Pegou
## Buriti", "Mochila cheia").

const HEART_FULL := preload("res://assets/art/ui/heart_full.png")
const HEART_HALF := preload("res://assets/art/ui/heart_half.png")
const HEART_EMPTY := preload("res://assets/art/ui/heart_empty.png")
const HEART_SIZE := Vector2(36, 30)

## Quanto tempo um aviso fica na tela, em segundos.
const MESSAGE_SECONDS := 2.5

@onready var _hearts_box: HBoxContainer = $Root/HeartsBox
@onready var _light_bar: ProgressBar = $Root/LightBox/LightBar
@onready var _location_label: Label = $Root/LocationPanel/LocationLabel
@onready var _backpack_label: Label = $Root/BackpackPanel/BackpackLabel
@onready var _message_label: Label = $Root/MessageLabel
@onready var _message_timer: Timer = $MessageTimer


func _ready() -> void:
	_message_timer.wait_time = MESSAGE_SECONDS
	_message_timer.timeout.connect(_message_label.hide)
	_message_label.hide()


## Mostra os corações. `current` e `maximum` vêm em meios corações: cada ícone
## fica cheio, pela metade ou vazio.
func show_hearts(current: int, maximum: int) -> void:
	var count := ceili(float(maximum) / Hearts.HALVES_PER_HEART)
	while _hearts_box.get_child_count() > count:
		var extra := _hearts_box.get_child(_hearts_box.get_child_count() - 1)
		_hearts_box.remove_child(extra)
		extra.queue_free()
	while _hearts_box.get_child_count() < count:
		_hearts_box.add_child(_new_heart())
	for i in count:
		(_hearts_box.get_child(i) as TextureRect).texture = heart_texture(
			Hearts.fill_of(i, current)
		)


## Quantos corações cheios estão na tela.
func full_hearts() -> int:
	return _hearts_with(HEART_FULL)


## Quantos corações pela metade estão na tela.
func half_hearts() -> int:
	return _hearts_with(HEART_HALF)


## Imagem do coração para cada preenchimento.
static func heart_texture(fill: Hearts.Fill) -> Texture2D:
	match fill:
		Hearts.Fill.FULL:
			return HEART_FULL
		Hearts.Fill.HALF:
			return HEART_HALF
	return HEART_EMPTY


## Mostra a luz do gato: a barra vai de vazia (luz inicial) a cheia (luz máxima).
func show_light(defeated: int) -> void:
	_light_bar.value = light_fraction(defeated)


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


## Quanto da luz (de 0 a 1) o gato tem com `defeated` criaturas derrotadas.
static func light_fraction(defeated: int) -> float:
	var light := LightRadius.for_defeated(defeated)
	return (light - LightRadius.BASE) / (LightRadius.MAX - LightRadius.BASE)


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


func _hearts_with(texture: Texture2D) -> int:
	var found := 0
	for heart: TextureRect in _hearts_box.get_children():
		if heart.texture == texture:
			found += 1
	return found


func _new_heart() -> TextureRect:
	var heart := TextureRect.new()
	heart.custom_minimum_size = HEART_SIZE
	heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return heart
