class_name RegionFloor
extends Node2D
## Um andar de uma região: o labirinto, o Mingau, a porta de saída e a
## interface. Gera o andar ao abrir a cena e de novo a cada subida de andar ou
## troca de região, sempre sorteando um mapa novo.
##
## A região e o andar vêm do `GameState`. Mochila e estoque também ficam lá, então
## subir, voltar à cabana e trocar de região não os perdem.
##
## O Mingau tem 7 corações; se zerarem, ele desmaia e acorda na cabana.
##
## O andar fica no escuro (`Darkness`): só o círculo de luz do gato ilumina, e
## ele volta ao tamanho inicial a cada andar gerado.

## Emitido quando um andar novo foi gerado e o gato já está na entrada.
signal floor_generated(layout: MazeLayout)

## Região usada se a cena for aberta direto, sem passar pela cabana.
const DEFAULT_REGION := Regions.AMAZONIA

const IngredientPickupScene := preload("res://scenes/region/ingredient_pickup.tscn")
const CreatureScene := preload("res://scenes/creatures/creature.tscn")

## Segundos entre o desmaio do gato e a chegada à cabana.
@export var faint_seconds := 1.5

@onready var _room: Room = $Room
@onready var _player: Player = $World/Player
@onready var _light: PlayerLight = $World/Player/Light
@onready var _items: Node2D = $World/Items
@onready var _creatures: Node2D = $World/Creatures
@onready var _exit_door: InteractionArea = $World/ExitDoor
@onready var _hud: Hud = $Hud
@onready var _banner: RegionBanner = $RegionBanner
@onready var _door_menu: DoorMenu = $DoorMenu
@onready var _region_menu: RegionMenu = $RegionMenu


func _ready() -> void:
	# O andar sempre abre explorando, mesmo que a cena anterior tenha saído com
	# um menu aberto.
	GameState.flow.reset()
	if not Regions.is_valid(GameState.current_region):
		GameState.start_region(DEFAULT_REGION)
	Music.play_region(GameState.current_region)
	_exit_door.interacted.connect(_on_exit_door_interacted)
	_door_menu.choice_made.connect(_on_door_choice_made)
	_region_menu.region_selected.connect(_on_region_selected)
	_player.hearts.changed.connect(_hud.show_hearts)
	_player.fainted.connect(_on_player_fainted)
	_hud.show_hearts(_player.hearts.current, Hearts.MAX)
	GameState.backpack.changed.connect(_on_backpack_changed)
	GameState.backpack.rejected.connect(_on_backpack_rejected)
	_door_menu.closed.connect(_on_menu_closed)
	_region_menu.closed.connect(_on_menu_closed)
	generate_floor()


## Ao sair da cena (troca de cena), o jogo volta a explorar: a próxima cena não
## herda um diálogo ou menu que ficou aberto.
func _exit_tree() -> void:
	GameState.flow.reset()


## Gera o andar da região e do andar atuais do `GameState` e leva o gato à
## entrada. É só aqui que o labirinto é sorteado.
func generate_floor() -> void:
	var ingredients := ingredients_for_floor()
	_room.params.items = ingredients.size()
	var layout := _room.generate(GameState.current_region)
	_player.position = _room.cell_to_position(layout.entry_cell)
	_player.velocity = Vector2.ZERO
	_light.reset()
	_player.set_camera_limits(_room.bounds())
	_exit_door.position = _room.cell_to_position(layout.exit_cell)
	_hud.show_location(GameState.current_region, GameState.current_floor)
	_hud.show_backpack(GameState.backpack)
	_hud.show_light(0)
	if GameState.current_floor == GameState.FIRST_FLOOR:
		_banner.show_region(GameState.current_region, GameState.current_floor)
	_spawn_ingredients(ingredients, layout)
	_spawn_creatures(layout)
	floor_generated.emit(layout)


## Ingredientes que aparecem no andar atual: os da região e da paridade do
## andar, segundo o CSV (Tabela 2).
func ingredients_for_floor() -> Array[Ingredient]:
	return IngredientData.get_ingredients_in(GameState.current_region, GameState.floor_parity())


## Ingredientes que estão no chão agora.
func get_pickups() -> Array[IngredientPickup]:
	var result: Array[IngredientPickup] = []
	for child in _items.get_children():
		if not child.is_queued_for_deletion():
			result.append(child as IngredientPickup)
	return result


## Criaturas vivas no andar agora.
func get_creatures() -> Array[Creature]:
	var result: Array[Creature] = []
	for child in _creatures.get_children():
		var creature := child as Creature
		if not creature.is_queued_for_deletion() and not creature.is_defeated():
			result.append(creature)
	return result


## Troca as criaturas pelas do andar novo, nas células que o gerador reservou
## (longe da entrada, sem fechar o caminho). A quantidade vem de
## `Room.params.entities`.
func _spawn_creatures(layout: MazeLayout) -> void:
	for old in _creatures.get_children():
		old.queue_free()
	for cell in layout.creature_cells:
		var creature: Creature = CreatureScene.instantiate()
		creature.position = _room.cell_to_position(cell)
		creature.setup(layout.grid, _player)
		creature.defeated.connect(_on_creature_defeated)
		_creatures.add_child(creature)


## Os corações zeraram: o gato desmaia e acorda na cabana. A mochila e o estoque
## ficam como estavam (estão no `GameState`) e os corações voltam a 7, porque a
## cabana cria um Mingau novo.
func _on_player_fainted() -> void:
	_hud.show_message("Mingau desmaiou... acordando na cabana")
	await get_tree().create_timer(faint_seconds).timeout
	# Um menu aberto nesse meio tempo deixaria a cabana em pausa.
	GameState.flow.reset()
	GameState.leave_region()
	get_tree().change_scene_to_file(ScenePaths.CABIN)


## Cada criatura derrotada aumenta a luz do andar.
func _on_creature_defeated(_creature: Creature) -> void:
	_light.add_defeat()
	_hud.show_light(_light.defeated)


## Troca os ingredientes do chão pelos do andar novo, cada um numa das células
## reservadas pelo gerador (todas alcançáveis a partir da entrada).
func _spawn_ingredients(ingredients: Array[Ingredient], layout: MazeLayout) -> void:
	for old in _items.get_children():
		old.queue_free()
	for i in mini(ingredients.size(), layout.item_cells.size()):
		var pickup: IngredientPickup = IngredientPickupScene.instantiate()
		pickup.ingredient_id = ingredients[i].id
		pickup.position = _room.cell_to_position(layout.item_cells[i])
		pickup.touched.connect(_on_pickup_touched)
		_items.add_child(pickup)


## Coleta: o ingrediente vai para a mochila e some do chão. Com a mochila cheia
## ele fica onde está e a tela avisa.
func _on_pickup_touched(pickup: IngredientPickup) -> void:
	if pickup.is_queued_for_deletion():
		return
	if GameState.backpack.add(pickup.ingredient_id):
		pickup.queue_free()
		_hud.show_message("Pegou %s" % pickup.display_name())


func _on_backpack_changed() -> void:
	_hud.show_backpack(GameState.backpack)


func _on_backpack_rejected(id: String) -> void:
	var ingredient := IngredientData.get_ingredient(id)
	var item_name := ingredient.display_name if ingredient != null else id
	_hud.show_message("Mochila cheia: %s ficou no chão" % item_name)


func _on_exit_door_interacted(_id: StringName) -> void:
	if GameState.flow.open_menu():
		_door_menu.open(GameState.current_floor)


func _on_door_choice_made(choice: StringName) -> void:
	match choice:
		DoorMenu.UP:
			GameState.climb_floor()
			generate_floor()
		DoorMenu.CABIN:
			GameState.leave_region()
			get_tree().change_scene_to_file(ScenePaths.CABIN)
		DoorMenu.OTHER_REGION:
			if GameState.flow.open_menu():
				_region_menu.open(GameState.current_region)


func _on_region_selected(region: String) -> void:
	GameState.start_region(region)
	generate_floor()


## Qualquer menu fechado volta à exploração. Se a escolha abrir outro menu (ir a
## outra região), ele pede o estado de menu de novo.
func _on_menu_closed() -> void:
	GameState.flow.close_menu()
