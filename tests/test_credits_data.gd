extends GutTest
## Confere a leitura do data/creditos.csv pela `CreditsData`, usada na tela
## Fontes para mostrar os créditos de arte e de áudio.


func test_reads_every_row_with_named_columns() -> void:
	var rows := CreditsData.load_rows()
	assert_gt(rows.size(), 0)
	for row in rows:
		for column in ["nome", "autor", "origem", "finalidade", "licenca", "tipo"]:
			assert_false(str(row.get(column, "")).is_empty(), "%s sem %s" % [row, column])


func test_types_split_the_rows() -> void:
	var rows := CreditsData.load_rows()
	var art := CreditsData.of_type(rows, CreditsData.ART)
	var audio := CreditsData.of_type(rows, CreditsData.AUDIO)
	assert_gt(art.size(), 0)
	assert_gt(audio.size(), 0)
	assert_eq(art.size() + audio.size(), rows.size())


func test_missing_file_gives_no_rows() -> void:
	var rows := CreditsData.load_rows("res://data/nao_existe.csv")
	assert_push_error("Não foi possível abrir")
	assert_true(rows.is_empty())
