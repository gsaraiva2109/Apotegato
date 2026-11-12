class_name DialogueLine
extends RefCounted
## Uma fala da caixa de diálogo: quem fala, o nome mostrado e o texto. A última
## fala de uma conversa pode trazer escolhas (`choices`), cada uma com `id` e
## `text`.

## Quem fala: "apothecary", "mingau" ou "patient".
var speaker: String
## Nome que aparece na caixa, já resolvido ("Apotecária", "Mingau", o nome do
## paciente).
var speaker_name: String
var text: String
## Opções de escolha, cada uma {"id": String, "text": String}. Vazio: sem escolha.
var choices: Array[Dictionary] = []


func _init(
	p_speaker: String = "",
	p_speaker_name: String = "",
	p_text: String = "",
	p_choices: Array[Dictionary] = []
) -> void:
	speaker = p_speaker
	speaker_name = p_speaker_name
	text = p_text
	choices = p_choices


func has_choices() -> bool:
	return not choices.is_empty()
