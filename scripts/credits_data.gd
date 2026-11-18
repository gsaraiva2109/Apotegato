class_name CreditsData
extends RefCounted
## Lê o data/creditos.csv, o registro dos assets de terceiros (GDD, seção 5).
## Cada linha vira um dicionário com `nome`, `autor`, `origem`, `finalidade`,
## `licenca` e `tipo` ("arte" ou "audio"). Quem usa é a tela Fontes.

const PATH := "res://data/creditos.csv"
const ART := "arte"
const AUDIO := "audio"


## Todas as linhas do registro, na ordem do arquivo. Vazio se não der para ler.
static func load_rows(path: String = PATH) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir %s" % path)
		return rows
	var header := file.get_csv_line()
	while not file.eof_reached():
		var line := file.get_csv_line()
		if line.size() != header.size():
			continue
		var row := {}
		for i in header.size():
			row[header[i]] = line[i]
		rows.append(row)
	return rows


## Só as linhas de um tipo ("arte" ou "audio").
static func of_type(rows: Array[Dictionary], type: String) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for row in rows:
		if row.get("tipo", "") == type:
			found.append(row)
	return found
