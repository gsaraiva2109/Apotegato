extends GutTest
## Confere o elenco (data/elenco.csv): a apotecária e um paciente para cada uma
## das 10 condições do CSV de ingredientes.

const CSV_PATH := "res://data/elenco.csv"
const HEADER := ["id", "nome", "condicao", "descricao"]

var _rows: Array[PackedStringArray] = []


func before_each() -> void:
	_rows.clear()
	var file := FileAccess.open(CSV_PATH, FileAccess.READ)
	assert_eq(Array(file.get_csv_line()), HEADER)
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() == 1 and row[0].is_empty():
			continue
		_rows.append(row)


func test_has_apothecary_and_ten_patients() -> void:
	assert_eq(_rows.size(), 11)
	for i in _rows.size():
		assert_eq(_rows[i].size(), HEADER.size())
		assert_eq(_rows[i][0], "SER-%d" % (i + 1))
	assert_eq(_rows[0][2], "", "a apotecária não tem condição")


func test_each_condition_has_exactly_one_patient() -> void:
	var conditions := []
	for i in range(1, _rows.size()):
		conditions.append(_rows[i][2])
	var expected := Array(IngredientData.get_conditions())
	conditions.sort()
	expected.sort()
	assert_eq(conditions, expected)


func test_names_and_descriptions_are_filled_and_unique() -> void:
	var names := []
	for row in _rows:
		assert_false(row[1].strip_edges().is_empty())
		assert_false(row[3].strip_edges().is_empty())
		assert_does_not_have(names, row[1], "nome repetido: %s" % row[1])
		names.append(row[1])
