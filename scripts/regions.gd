class_name Regions
extends RefCounted
## As seis regiões do jogo. Os ids são os mesmos da coluna "regiao" do
## data/ingredientes.csv; os nomes são os que aparecem na tela.

const AMAZONIA := "amazonia"
const CAATINGA := "caatinga"
const CAMPOS_RIOS := "campos_rios"
const CERRADO := "cerrado"
const LITORAL := "litoral"
const MATA_ATLANTICA := "mata_atlantica"

## Ids das regiões, na ordem em que aparecem nos menus.
const IDS: Array[String] = [
	AMAZONIA,
	CAATINGA,
	CAMPOS_RIOS,
	CERRADO,
	LITORAL,
	MATA_ATLANTICA,
]

const NAMES := {
	AMAZONIA: "Amazônia",
	CAATINGA: "Caatinga",
	CAMPOS_RIOS: "Campos e Rios",
	CERRADO: "Cerrado",
	LITORAL: "Litoral",
	MATA_ATLANTICA: "Mata Atlântica",
}

## Pasta onde fica o tileset de cada região (uma subpasta por id).
const ART_DIR := "res://assets/art/regions"


## Nome da região para mostrar na tela. Se o id for desconhecido, devolve o
## próprio id.
static func display_name(region: String) -> String:
	return NAMES.get(region, region)


## Caminho do PNG do tileset da região (128 x 32, quatro tiles).
static func tileset_path(region: String) -> String:
	return "%s/%s/tileset.png" % [ART_DIR, region]


static func is_valid(region: String) -> bool:
	return region in IDS
