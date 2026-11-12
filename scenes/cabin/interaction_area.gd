class_name InteractionArea
extends Area2D
## Ponto de interação da cabana (porta, apotecária, paciente, estoque). Quando o
## Mingau chega perto aparece o aviso "E"; apertar `interact` emite `interacted`.
##
## Só funciona na exploração: em diálogo, entrega ou menu o aviso some e o E não
## dispara. Um ponto desligado (`enabled = false`, como o do paciente quando não
## há ninguém na cabana) também não.

## Emitido quando o jogador aperta `interact` com o Mingau dentro da área.
signal interacted(id: StringName)

## Identificador do ponto (ex.: `door`, `apothecary`, `patient`).
@export var id: StringName = &""

## Tamanho da área de detecção, em pixels.
@export var size := Vector2(64, 64)

## Se o ponto aceita interação. Desligado, o aviso não aparece.
@export var enabled := true:
	set(value):
		enabled = value
		_update_prompt()

var _player_inside := false

@onready var _prompt: Control = $Prompt


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape.shape = shape
	_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.flow.state_changed.connect(_on_flow_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and try_interact():
		get_viewport().set_input_as_handled()


## Interage se o Mingau estiver na área, o ponto estiver ligado e o jogo estiver
## na exploração. Devolve se houve interação.
func try_interact() -> bool:
	if not _can_interact():
		return false
	interacted.emit(id)
	return true


## Se o aviso "E" está aparecendo.
func is_prompt_visible() -> bool:
	return _prompt.visible


func _can_interact() -> bool:
	return _player_inside and enabled and GameState.flow.can_player_act()


func _update_prompt() -> void:
	if _prompt != null:
		_prompt.visible = _can_interact()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		_update_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
		_update_prompt()


func _on_flow_state_changed(_from: GameFlow.State, _to: GameFlow.State) -> void:
	_update_prompt()
