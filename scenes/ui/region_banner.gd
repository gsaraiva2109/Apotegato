class_name RegionBanner
extends CanvasLayer
## Faixa com o nome da região, mostrada por alguns segundos quando o Mingau
## entra nela (primeiro andar) e que some aos poucos. Não bloqueia o mouse.

## Segundos que a faixa fica inteira na tela antes de sumir.
const HOLD_SECONDS := 2.0
## Segundos da entrada e da saída gradual.
const FADE_SECONDS := 0.4

var _tween: Tween

@onready var _root: Control = $Root
@onready var _name_label: Label = $Root/Plate/Layout/RegionName
@onready var _floor_label: Label = $Root/Plate/Layout/FloorLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.modulate.a = 0.0
	_root.hide()


## Mostra o nome da região e o andar, e some depois de `HOLD_SECONDS`.
func show_region(region: String, floor_number: int) -> void:
	_name_label.text = Regions.display_name(region)
	_floor_label.text = "Andar %d" % floor_number
	if _tween != null:
		_tween.kill()
	_root.show()
	_tween = create_tween()
	_tween.tween_property(_root, "modulate:a", 1.0, FADE_SECONDS)
	_tween.tween_interval(HOLD_SECONDS)
	_tween.tween_property(_root, "modulate:a", 0.0, FADE_SECONDS)
	_tween.tween_callback(_root.hide)
