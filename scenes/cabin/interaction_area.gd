class_name InteractionArea
extends Area2D
## Ponto de interação da cabana (porta, diário, paciente). Quando o Mingau
## chega perto aparece o aviso "E"; apertar `interact` emite `interacted`.

## Emitido quando o jogador aperta `interact` com o Mingau dentro da área.
signal interacted(id: StringName)

## Identificador do ponto (ex.: `door`, `journal`, `patient`).
@export var id: StringName = &""

## Tamanho da área de detecção, em pixels.
@export var size := Vector2(64, 64)

var _player_inside := false

@onready var _prompt: Control = $Prompt


func _ready() -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	$CollisionShape.shape = shape
	_prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and try_interact():
		get_viewport().set_input_as_handled()


## Interage se o Mingau estiver na área. Devolve se houve interação.
func try_interact() -> bool:
	if not _player_inside:
		return false
	interacted.emit(id)
	return true


## Se o aviso "E" está aparecendo.
func is_prompt_visible() -> bool:
	return _prompt.visible


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_inside = true
		_prompt.visible = true


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_inside = false
		_prompt.visible = false
