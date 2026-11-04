extends GutTest
## Valida o data/creditos.csv, o registro de assets de terceiros lido pela tela Créditos.
##
## Todo asset de terceiros entra aqui com nome, autor, origem, finalidade e licença
## (GDD, seção 5). Se mudar as colunas, atualize HEADER junto com o CSV.

const CSV_PATH := "res://data/creditos.csv"
const HEADER := ["nome", "autor", "origem", "finalidade", "licenca", "tipo"]
const TYPES := ["arte", "audio"]

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


func test_has_at_least_one_credit() -> void:
	assert_gt(_rows.size(), 0, "O registro de créditos está vazio")


func test_every_row_has_all_columns_filled() -> void:
	for row in _rows:
		assert_eq(row.size(), HEADER.size(), "Linha com colunas a mais ou a menos: %s" % row[0])
		for value in row:
			assert_false(value.strip_edges().is_empty(), "Campo vazio em: %s" % row[0])


func test_types_are_valid() -> void:
	for row in _rows:
		assert_has(TYPES, row[HEADER.find("tipo")], "Tipo inválido em: %s" % row[0])


func test_origins_are_links() -> void:
	for row in _rows:
		assert_true(
			row[HEADER.find("origem")].begins_with("https://"), "Origem sem link em: %s" % row[0]
		)
