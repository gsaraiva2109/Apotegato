class_name Ingredient
extends RefCounted
## Um ingrediente lido do data/ingredientes.csv. Os valores de id, região,
## paridade e condições são os do CSV, sem tradução.

var id: String
## Nome que aparece no jogo (coluna "nome").
var display_name: String
var region: String
## "impar" ou "par".
var parity: String
## Ids das condições em que o ingrediente entra, já sem o sufixo ":ou".
var conditions: PackedStringArray


func _init(
	p_id: String,
	p_display_name: String,
	p_region: String,
	p_parity: String,
	p_conditions: PackedStringArray
) -> void:
	id = p_id
	display_name = p_display_name
	region = p_region
	parity = p_parity
	conditions = p_conditions
