class_name Cabin
extends Node2D
## A cabana da apotecária: sala de 30 x 17 tiles onde o Mingau anda e de onde
## partem a porta para as regiões, o diário e o atendimento do paciente.

## Emitido quando o Mingau interage com um ponto da cabana (`door`,
## `journal`, `stock` ou `patient`). A porta abre a escolha de região e a
## estante abre o estoque; as próximas sprints ligam o paciente a uma tela.
signal interacted(id: StringName)
## Emitido quando a entrega de ingredientes cobre a condição do paciente.
signal delivery_completed(condition: String)

## Tamanho da cabana em pixels (30 x 17 tiles de 32 px).
const ROOM := Rect2i(0, 0, 960, 544)

## Condição do paciente que está na cabana (id do CSV), definida por quem cuida
## do atendimento. Vazia: não há paciente, e a mochila só mostra o conteúdo.
var current_condition: String = ""

@onready var _player: Player = $World/Player
@onready var _region_menu: RegionMenu = $RegionMenu
@onready var _stock_menu: StockMenu = $StockMenu
@onready var _backpack_menu: BackpackMenu = $BackpackMenu


func _ready() -> void:
	Music.play(Music.CABIN)
	_player.set_camera_limits(ROOM)
	for area: InteractionArea in $Interactions.get_children():
		area.interacted.connect(_on_interacted)
	_region_menu.region_selected.connect(_on_region_selected)
	_region_menu.closed.connect(_on_region_menu_closed)
	_stock_menu.closed.connect(_on_stock_menu_closed)
	_backpack_menu.hearts = _player.hearts
	_backpack_menu.closed.connect(_on_backpack_menu_closed)
	_backpack_menu.delivery_completed.connect(_on_delivery_completed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("backpack") and not get_tree().paused:
		_open_backpack()
		get_viewport().set_input_as_handled()


func _on_interacted(id: StringName) -> void:
	interacted.emit(id)
	if id == &"door":
		get_tree().paused = true
		_region_menu.open()
	elif id == &"stock":
		get_tree().paused = true
		_stock_menu.open()
	elif id == &"patient":
		_open_backpack()


## A região escolhida sempre começa no andar 1. A mochila e o estoque seguem
## como estavam.
func _on_region_selected(region: String) -> void:
	GameState.start_region(region)
	get_tree().change_scene_to_file(ScenePaths.FLOOR)


func _on_region_menu_closed() -> void:
	get_tree().paused = false


func _on_stock_menu_closed() -> void:
	get_tree().paused = false


## Abre a mochila; com paciente na cabana, ela também entrega os ingredientes.
func _open_backpack() -> void:
	get_tree().paused = true
	_backpack_menu.open(current_condition)


func _on_backpack_menu_closed() -> void:
	get_tree().paused = false


## A entrega cobriu a condição. O diálogo de orientação, o agradecimento e a saída
## do paciente (e só então marcá-lo como atendido) ficam com o atendimento.
func _on_delivery_completed(condition: String) -> void:
	delivery_completed.emit(condition)
