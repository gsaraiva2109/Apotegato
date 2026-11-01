class_name Hud
extends CanvasLayer
## Interface da exploração: região e andar, o contador da mochila e os avisos
## rápidos ("Pegou Buriti", "Mochila cheia"). As outras peças (corações)
## entram aqui conforme ficam prontas.

## Quanto tempo um aviso fica na tela, em segundos.
const MESSAGE_SECONDS := 2.5

@onready var _location_label: Label = $Root/LocationPanel/LocationLabel
@onready var _backpack_label: Label = $Root/BackpackPanel/BackpackLabel
@onready var _message_label: Label = $Root/MessageLabel
@onready var _message_timer: Timer = $MessageTimer


func _ready() -> void:
	_message_timer.wait_time = MESSAGE_SECONDS
	_message_timer.timeout.connect(_message_label.hide)
	_message_label.hide()


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
