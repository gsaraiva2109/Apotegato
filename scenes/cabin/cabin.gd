class_name Cabin
extends Node2D
## A cabana da apotecária: sala de 30 x 17 tiles onde o Mingau anda e de onde
## partem a porta para as regiões, o diário e o atendimento do paciente.

## Emitido quando o Mingau interage com um ponto da cabana (`door`,
## `journal` ou `patient`). A porta abre a escolha de região; as próximas
## sprints ligam o diário e o paciente a uma tela.
signal interacted(id: StringName)

## Tamanho da cabana em pixels (30 x 17 tiles de 32 px).
const ROOM := Rect2i(0, 0, 960, 544)

@onready var _player: Player = $World/Player
@onready var _region_menu: RegionMenu = $RegionMenu


func _ready() -> void:
	Music.play(MusicCatalog.CABIN)
	_player.set_camera_limits(ROOM)
	for area: InteractionArea in $Interactions.get_children():
		area.interacted.connect(_on_interacted)
	_region_menu.region_selected.connect(_on_region_selected)
	_region_menu.closed.connect(_on_region_menu_closed)


func _on_interacted(id: StringName) -> void:
	interacted.emit(id)
	if id == &"door":
		get_tree().paused = true
		_region_menu.open()


## A região escolhida sempre começa no andar 1. A mochila e o estoque seguem
## como estavam.
func _on_region_selected(region: String) -> void:
	GameState.start_region(region)
	get_tree().change_scene_to_file(ScenePaths.FLOOR)


func _on_region_menu_closed() -> void:
	get_tree().paused = false
