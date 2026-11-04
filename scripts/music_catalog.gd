class_name MusicCatalog
extends RefCounted
## Quais faixas existem e onde ficam. São oito: menu, cabana e uma por região.
## Os arquivos de música de terceiros não vão no git (as licenças proíbem
## redistribuir): ficam no repositório privado ApotegatoAssets e são baixados
## por tools/fetch_assets.sh para assets/audio/third_party/music/.

const MENU := "menu"
const CABIN := "cabana"

## Pasta das faixas, com um arquivo `<id>.ogg` por faixa.
const MUSIC_DIR := "res://assets/audio/third_party/music"
const EXTENSION := "ogg"


## Ids de todas as faixas: menu, cabana e as seis regiões (mesmos ids do CSV).
static func all_ids() -> Array[String]:
	var ids: Array[String] = [MENU, CABIN]
	ids.append_array(Regions.IDS)
	return ids


## Id da faixa de uma região; vazio se a região for desconhecida.
static func track_for_region(region: String) -> String:
	return region if Regions.is_valid(region) else ""


static func path_for(track: String) -> String:
	return "%s/%s.%s" % [MUSIC_DIR, track, EXTENSION]
