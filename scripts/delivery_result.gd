class_name DeliveryResult
extends RefCounted
## O que aconteceu numa entrega (`Delivery.deliver`). A tela e o diálogo leem
## daqui para escolher a fala e a mensagem.

## Um dos valores de `Delivery.Outcome`.
var outcome: Delivery.Outcome = Delivery.Outcome.EMPTY_BACKPACK
## Ids que saíram da mochila e foram para o estoque nesta entrega.
var stored: Array[String] = []
## Ids gastos do estoque ao completar a condição.
var consumed: Array[String] = []
## Requisitos que ainda faltam (cada item é um grupo em que basta um id).
var missing: Array[PackedStringArray] = []
## Sobras na mochila (id -> quantidade) que não servem a este paciente.
var surplus: Dictionary = {}


## Nomes dos requisitos que faltam, como "Camu-Camu ou Acerola".
func missing_labels() -> Array[String]:
	var labels: Array[String] = []
	for group in missing:
		labels.append(Delivery.group_label(group))
	return labels


## Os que faltam em uma frase: "Mel, Buriti e Camu-Camu ou Acerola".
func missing_text() -> String:
	return Delivery.join_labels(missing_labels())
