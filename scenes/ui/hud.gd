class_name Hud
extends CanvasLayer
## Interface da exploração: região e andar na tela. As outras peças (mochila,
## corações) entram aqui conforme ficam prontas.

@onready var _location_label: Label = $Root/LocationPanel/LocationLabel


## Mostra a região e o andar, como "Amazônia - Andar 2".
func show_location(region: String, floor_number: int) -> void:
	_location_label.text = location_text(region, floor_number)


## Texto da região e do andar. Fica separado para ser testado.
static func location_text(region: String, floor_number: int) -> String:
	return "%s - Andar %d" % [Regions.display_name(region), floor_number]
