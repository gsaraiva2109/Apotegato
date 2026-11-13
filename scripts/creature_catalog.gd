class_name CreatureCatalog
extends RefCounted
## O catálogo das criaturas, lido do data/criaturas.csv. Cada linha é uma
## criatura, com a região onde aparece, o dano que causa (em meios corações),
## quantos arranhões a derrotam, a velocidade, o primeiro andar em que pode
## aparecer, o peso dela no sorteio e a pasta da arte dela (`sprite`, ver
## `CreatureSprites`).
##
## É lógica pura, sem cena e sem autoload: quem precisa (o andar) cria um
## catálogo com `load_default()`. O sorteio recebe o gerador de números
## aleatórios, então os testes usam uma semente fixa.

const CSV_PATH := "res://data/criaturas.csv"
const HEADER := [
	"id", "nome", "regiao", "dano", "golpes", "velocidade", "andar_minimo", "peso", "sprite"
]


## Uma criatura do catálogo.
class Entry:
	extends RefCounted
	var id: String
	var display_name: String
	var region: String
	## Dano de cada golpe, em meios corações.
	var damage: int
	## Quantos arranhões a derrotam.
	var hits: int
	## Velocidade de perseguição, em pixels por segundo.
	var speed: float
	## Primeiro andar em que ela pode aparecer.
	var min_floor: int
	## Chance relativa no sorteio.
	var weight: int
	## Nome da pasta de arte em `assets/art/creatures/` (o bicho que a criatura é).
	var sprite: String

	## Se ela machuca um coração inteiro ou mais (usado só para a arte provisória
	## da forte, até a #38 trazer a arte de verdade).
	func is_strong() -> bool:
		return damage >= Hearts.HALVES_PER_HEART


## As criaturas, na ordem do CSV.
var _entries: Array[Entry] = []


## Catálogo com o data/criaturas.csv do jogo.
static func load_default() -> CreatureCatalog:
	var catalog := CreatureCatalog.new()
	if not catalog.load_csv(CSV_PATH):
		push_error("CreatureCatalog: não foi possível carregar %s" % CSV_PATH)
	return catalog


## Lê o CSV e substitui as criaturas carregadas. Devolve false se o arquivo não
## abrir ou se o cabeçalho for diferente do esperado. Linhas inválidas são
## puladas, com erro no log.
func load_csv(path: String) -> bool:
	_entries.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	if Array(file.get_csv_line()) != HEADER:
		push_error("CreatureCatalog: cabeçalho inesperado em %s" % path)
		return false
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].strip_edges().is_empty():
			continue
		if row.size() != HEADER.size():
			push_error("CreatureCatalog: linha inválida em %s: %s" % [path, row])
			continue
		var entry := Entry.new()
		entry.id = row[0]
		entry.display_name = row[1]
		entry.region = row[2]
		entry.damage = row[3].to_int()
		entry.hits = row[4].to_int()
		entry.speed = row[5].to_float()
		entry.min_floor = row[6].to_int()
		entry.weight = row[7].to_int()
		entry.sprite = row[8]
		_entries.append(entry)
	return true


## Todas as criaturas, na ordem do CSV.
func all() -> Array[Entry]:
	return _entries


## Criatura com esse id, ou null.
func get_entry(id: String) -> Entry:
	for entry in _entries:
		if entry.id == id:
			return entry
	return null


## As criaturas que podem aparecer nessa região nesse andar.
func entries_for(region: String, floor_number: int) -> Array[Entry]:
	var result: Array[Entry] = []
	for entry in _entries:
		if entry.region == region and entry.min_floor <= floor_number and entry.weight > 0:
			result.append(entry)
	return result


## Sorteia a criatura de uma célula pela região e pelo andar, respeitando o peso
## de cada uma. Devolve null se a região não tem criatura liberada nesse andar.
func pick(region: String, floor_number: int, rng: RandomNumberGenerator) -> Entry:
	var candidates := entries_for(region, floor_number)
	if candidates.is_empty():
		return null
	var total := 0
	for entry in candidates:
		total += entry.weight
	var roll := rng.randi_range(1, total)
	for entry in candidates:
		roll -= entry.weight
		if roll <= 0:
			return entry
	return candidates[-1]
