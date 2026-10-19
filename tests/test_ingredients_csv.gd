extends GutTest
## Valida o data/ingredientes.csv contra as regras do GDD (Tabelas 1 e 2).
##
## Coluna "condicoes": ids separados por "|". O sufixo ":ou" marca um
## ingrediente alternativo: entre os marcados assim na mesma condição, basta um.
## Se o time mudar a lista de ingredientes ou de condições, atualize as
## constantes abaixo junto com o CSV.

const CSV_PATH := "res://data/ingredientes.csv"
const HEADER := ["id", "nome", "regiao", "paridade", "condicoes"]
const TOTAL_INGREDIENTS := 26
const REGIONS := ["amazonia", "caatinga", "campos_rios", "cerrado", "litoral", "mata_atlantica"]
const PARITIES := ["impar", "par"]
## Quantos ingredientes cada condição pede (um grupo ":ou" conta como um).
const ITEMS_PER_CONDITION := {
	"queimaduras": 3,
	"diarreia": 3,
	"anemia_ferropriva": 3,
	"insonia": 3,
	"xeroftalmia": 4,
	"escorbuto": 3,
	"resfriado": 4,
	"dor_muscular": 3,
	"gastrite": 3,
	"ossos_fracos": 3,
}

var _rows: Array[PackedStringArray] = []


func before_all() -> void:
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_not_null(file, "Não abriu %s" % CSV_PATH)
	if file == null:
		return
	var header := file.get_csv_line()
	assert_eq(Array(header), HEADER, "Cabeçalho do CSV mudou")
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].strip_edges().is_empty():
			continue
		_rows.append(row)


func test_total_ingredients() -> void:
	assert_eq(_rows.size(), TOTAL_INGREDIENTS)


func test_every_row_has_all_columns() -> void:
	for row in _rows:
		assert_eq(row.size(), HEADER.size(), "Linha com colunas faltando: %s" % [row])
		for field in row:
			assert_false(field.strip_edges().is_empty(), "Campo vazio em: %s" % [row])


func test_ids_are_unique_and_snake_case() -> void:
	var pattern := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	var seen := {}
	for row in _rows:
		var id := row[0]
		assert_not_null(pattern.search(id), "id fora do padrão: '%s'" % id)
		assert_false(seen.has(id), "id repetido: '%s'" % id)
		seen[id] = true


func test_region_and_parity_are_valid() -> void:
	for row in _rows:
		assert_has(REGIONS, row[2], "Região desconhecida em '%s'" % row[0])
		assert_has(PARITIES, row[3], "Paridade desconhecida em '%s'" % row[0])


func test_each_region_has_ingredients_in_both_parities() -> void:
	var counts := {}
	for row in _rows:
		var key: String = row[2] + "/" + row[3]
		counts[key] = counts.get(key, 0) + 1
	for region in REGIONS:
		for parity in PARITIES:
			var key: String = region + "/" + parity
			assert_gte(counts.get(key, 0), 2, "Poucos ingredientes em %s" % key)


func test_conditions_require_the_right_amount() -> void:
	var required := {}
	var alternatives := {}
	for row in _rows:
		for entry in row[4].split("|"):
			var parts := entry.split(":")
			var condition := parts[0]
			assert_true(
				ITEMS_PER_CONDITION.has(condition),
				"Condição desconhecida em '%s': %s" % [row[0], condition]
			)
			if parts.size() > 1:
				assert_eq(parts[1], "ou", "Modificador inválido em '%s': %s" % [row[0], entry])
				alternatives[condition] = alternatives.get(condition, 0) + 1
			else:
				required[condition] = required.get(condition, 0) + 1

	for condition in ITEMS_PER_CONDITION:
		var n_alternatives: int = alternatives.get(condition, 0)
		assert_ne(n_alternatives, 1, "'%s' tem um ingrediente ':ou' sozinho" % condition)
		var total: int = required.get(condition, 0) + mini(n_alternatives, 1)
		assert_eq(total, ITEMS_PER_CONDITION[condition], "Quantidade errada em '%s'" % condition)
