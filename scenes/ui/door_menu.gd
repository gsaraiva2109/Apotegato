class_name DoorMenu
extends CanvasLayer
## Menu da porta de saída do andar, com as três opções do jogo: subir de andar,
## voltar à cabana ou ir ao andar 1 de outra região. Não existe opção de descer:
## não dá para voltar a andares anteriores. Esc fecha e o gato segue explorando.

## Emitido quando o jogador escolhe uma opção (`UP`, `CABIN` ou
## `OTHER_REGION`). O menu já se fechou.
signal choice_made(choice: StringName)
## Emitido sempre que o menu se fecha, com ou sem escolha.
signal closed

const UP := &"up"
const CABIN := &"cabin"
const OTHER_REGION := &"other_region"

@onready var _up_button: Button = $Root/Center/Panel/Layout/UpButton
@onready var _cabin_button: Button = $Root/Center/Panel/Layout/CabinButton
@onready var _region_button: Button = $Root/Center/Panel/Layout/RegionButton
@onready var _cancel_button: Button = $Root/Center/Panel/Layout/CancelButton


func _ready() -> void:
	_up_button.pressed.connect(_choose.bind(UP))
	_cabin_button.pressed.connect(_choose.bind(CABIN))
	_region_button.pressed.connect(_choose.bind(OTHER_REGION))
	_cancel_button.pressed.connect(close)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Abre o menu para o andar em que o gato está.
func open(current_floor: int) -> void:
	_up_button.text = "Subir para o andar %d" % (current_floor + 1)
	visible = true
	_up_button.grab_focus()


func close() -> void:
	visible = false
	closed.emit()


func is_open() -> bool:
	return visible


func _choose(choice: StringName) -> void:
	close()
	choice_made.emit(choice)
