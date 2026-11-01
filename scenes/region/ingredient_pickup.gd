class_name IngredientPickup
extends Area2D
## Um ingrediente caído no chão do andar. Quando o Mingau encosta, avisa o
## andar com `touched`; quem decide se vai para a mochila (e se o item some do
## chão) é o andar, porque a mochila pode estar cheia.

## Emitido quando o Mingau encosta no ingrediente.
signal touched(pickup: IngredientPickup)

## Id do ingrediente (o mesmo do CSV). Defina antes de pôr a cena na árvore.
var ingredient_id: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Nome do ingrediente para mostrar na tela, vindo do CSV.
func display_name() -> String:
	var ingredient := IngredientData.get_ingredient(ingredient_id)
	return ingredient.display_name if ingredient != null else ingredient_id


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		touched.emit(self)
