class_name SfxCatalog
extends RefCounted
## Quais efeitos sonoros existem, quantas variações cada um tem e o ganho de
## cada um em dB (para equilibrar com a música e entre si). Os arquivos de
## terceiros não vão no git: ficam no repositório privado ApotegatoAssets e são
## baixados por tools/fetch_assets.sh para assets/audio/third_party/sfx/, no
## formato `<id>_<n>.ogg` (n a partir de 1).

const ARRANHAO := &"scratch"
const ARRANHAO_ACERTOU := &"scratch_hit"
const CRIATURA_DERROTADA := &"creature_defeat"
const DANO := &"hurt"
const DESMAIO := &"faint"
const COLETA := &"pickup"
const MOCHILA_CHEIA := &"backpack_full"
const PORTA := &"door"
const ENTREGA_COMPLETA := &"delivery_done"
const ENTREGA_PARCIAL := &"delivery_partial"
const ENTREGA_VAZIA := &"delivery_empty"
const CLIQUE := &"ui_click"

const SFX_DIR := "res://assets/audio/third_party/sfx"
const EXTENSION := "ogg"

## id -> { variants: quantidade de arquivos, gain: ganho em dB }.
const ENTRIES := {
	&"scratch": {"variants": 3, "gain": -4.0},
	&"scratch_hit": {"variants": 3, "gain": -2.0},
	&"creature_defeat": {"variants": 2, "gain": -2.0},
	&"hurt": {"variants": 2, "gain": 0.0},
	&"faint": {"variants": 1, "gain": 0.0},
	&"pickup": {"variants": 2, "gain": 0.0},
	&"backpack_full": {"variants": 1, "gain": -4.0},
	&"door": {"variants": 2, "gain": 0.0},
	&"delivery_done": {"variants": 1, "gain": -2.0},
	&"delivery_partial": {"variants": 1, "gain": -2.0},
	&"delivery_empty": {"variants": 1, "gain": -4.0},
	&"ui_click": {"variants": 2, "gain": -6.0},
}


## Ids de todos os efeitos.
static func all_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for id in ENTRIES:
		ids.append(id)
	return ids


static func has(id: StringName) -> bool:
	return ENTRIES.has(id)


## Quantas variações o efeito tem (0 se o id for desconhecido).
static func variants_of(id: StringName) -> int:
	return int(ENTRIES[id]["variants"]) if ENTRIES.has(id) else 0


## Ganho do efeito em dB (0 se o id for desconhecido).
static func gain_of(id: StringName) -> float:
	return float(ENTRIES[id]["gain"]) if ENTRIES.has(id) else 0.0


## Caminho do arquivo da variação `n` (a partir de 1).
static func path_for(id: StringName, n: int) -> String:
	return "%s/%s_%d.%s" % [SFX_DIR, id, n, EXTENSION]
