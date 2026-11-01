class_name RegionFloor
extends Node2D
## Um andar de uma região: o labirinto, o Mingau, a porta de saída e a
## interface. Gera o andar ao abrir a cena e de novo a cada subida de andar ou
## troca de região, sempre sorteando um mapa novo.
##
## A região e o andar vêm do `GameState`. Mochila e estoque também ficam lá, então
## subir, voltar à cabana e trocar de região não os perdem.

## Emitido quando um andar novo foi gerado e o gato já está na entrada.
signal floor_generated(layout: MazeLayout)

## Região usada se a cena for aberta direto, sem passar pela cabana.
const DEFAULT_REGION := Regions.AMAZONIA

const IngredientPickupScene := preload("res://scenes/region/ingredient_pickup.tscn")

@onready var _room: Room = $Room
@onready var _player: Player = $World/Player
@onready var _items: Node2D = $World/Items
@onready var _exit_door: InteractionArea = $World/ExitDoor
@onready var _hud: Hud = $Hud
@onready var _door_menu: DoorMenu = $DoorMenu
@onready var _region_menu: RegionMenu = $RegionMenu


func _ready() -> void:
	if not Regions.is_valid(GameState.current_region):
		GameState.start_region(DEFAULT_REGION)
	_exit_door.interacted.connect(_on_exit_door_interacted)
	_door_menu.choice_made.connect(_on_door_choice_made)
	_region_menu.region_selected.connect(_on_region_selected)
	GameState.backpack.changed.connect(_on_backpack_changed)
	GameState.backpack.rejected.connect(_on_backpack_rejected)
	_door_menu.closed.connect(_on_menu_closed)
	_region_menu.closed.connect(_on_menu_closed)
	generate_floor()


## Gera o andar da região e do andar atuais do `GameState` e leva o gato à
## entrada. É só aqui que o labirinto é sorteado.
func generate_floor() -> void:
	var ingredients := ingredients_for_floor()
	_room.params.items = ingredients.size()
	var layout := _room.generate(GameState.current_region)
	_player.position = _room.cell_to_position(layout.entry_cell)
	_player.velocity = Vector2.ZERO
	_player.set_camera_limits(_room.bounds())
	_exit_door.position = _room.cell_to_position(layout.exit_cell)
	_hud.show_location(GameState.current_region, GameState.current_floor)
	_hud.show_backpack(GameState.backpack)
	_spawn_ingredients(ingredients, layout)
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
	get_tree().paused = true
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
			get_tree().paused = true
			_region_menu.open(GameState.current_region)


func _on_region_selected(region: String) -> void:
	GameState.start_region(region)
	generate_floor()


## Qualquer menu fechado volta a rodar o jogo, a não ser que a escolha tenha
## aberto outro menu logo em seguida.
func _on_menu_closed() -> void:
	get_tree().paused = false
