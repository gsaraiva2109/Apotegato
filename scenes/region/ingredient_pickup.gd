class_name IngredientPickup
extends Area2D

signal touched(pickup: IngredientPickup)

var ingredient_id: String = ""

@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	_update_sprite()
	body_entered.connect(_on_body_entered)


func _update_sprite() -> void:
	if ingredient_id.is_empty():
		return

	var texture_path := "res://assets/art/ingredients/%s.png" % ingredient_id

	if not ResourceLoader.exists(texture_path):
		push_warning("Imagem do ingrediente não encontrada: %s. Usando placeholder." % texture_path)
		return

	var texture := load(texture_path) as Texture2D

	if texture == null:
		push_warning("Não foi possível carregar a imagem do ingrediente: %s" % texture_path)
		return

	_sprite.texture = texture


func display_name() -> String:
	var ingredient := IngredientData.get_ingredient(ingredient_id)
	return ingredient.display_name if ingredient != null else ingredient_id


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		touched.emit(self)
