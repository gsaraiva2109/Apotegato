extends GutTest
## Valida o data/ingredientes.csv contra as regras do GDD (Tabelas 1 e 2).
##
## Coluna "condicoes": ids separados por "|". O sufixo ":ou" marca um
## ingrediente alternativo: entre os marcados assim na mesma condição, basta um.
## Se o time mudar a lista de ingredientes ou de condições, atualize as
## constantes abaixo junto com o CSV.

const CAMINHO := "res://data/ingredientes.csv"
const CABECALHO := ["id", "nome", "regiao", "paridade", "condicoes"]
const TOTAL_INGREDIENTES := 26
const REGIOES := ["amazonia", "caatinga", "campos_rios", "cerrado", "litoral", "mata_atlantica"]
const PARIDADES := ["impar", "par"]
## Quantos ingredientes cada condição pede (um grupo ":ou" conta como um).
const ITENS_POR_CONDICAO := {
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

var _linhas: Array[PackedStringArray] = []


func before_all() -> void:
	var arquivo := FileAccess.open(CAMINHO, FileAccess.READ)
	assert_not_null(arquivo, "Não abriu %s" % CAMINHO)
	if arquivo == null:
		return
	var cabecalho := arquivo.get_csv_line()
	assert_eq(Array(cabecalho), CABECALHO, "Cabeçalho do CSV mudou")
	while not arquivo.eof_reached():
		var linha := arquivo.get_csv_line()
		if linha.size() == 1 and linha[0].strip_edges().is_empty():
			continue
		_linhas.append(linha)


func test_total_de_ingredientes() -> void:
	assert_eq(_linhas.size(), TOTAL_INGREDIENTES)


func test_toda_linha_tem_todas_as_colunas() -> void:
	for linha in _linhas:
		assert_eq(linha.size(), CABECALHO.size(), "Linha com colunas faltando: %s" % [linha])
		for campo in linha:
			assert_false(campo.strip_edges().is_empty(), "Campo vazio em: %s" % [linha])


func test_ids_unicos_e_em_snake_case() -> void:
	var formato := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	var vistos := {}
	for linha in _linhas:
		var id := linha[0]
		assert_not_null(formato.search(id), "id fora do padrão: '%s'" % id)
		assert_false(vistos.has(id), "id repetido: '%s'" % id)
		vistos[id] = true


func test_regiao_e_paridade_validas() -> void:
	for linha in _linhas:
		assert_has(REGIOES, linha[2], "Região desconhecida em '%s'" % linha[0])
		assert_has(PARIDADES, linha[3], "Paridade desconhecida em '%s'" % linha[0])


func test_cada_regiao_tem_ingredientes_nas_duas_paridades() -> void:
	var contagem := {}
	for linha in _linhas:
		var chave: String = linha[2] + "/" + linha[3]
		contagem[chave] = contagem.get(chave, 0) + 1
	for regiao in REGIOES:
		for paridade in PARIDADES:
			var chave: String = regiao + "/" + paridade
			assert_gte(contagem.get(chave, 0), 2, "Poucos ingredientes em %s" % chave)


func test_condicoes_pedem_a_quantidade_certa() -> void:
	var obrigatorios := {}
	var alternativos := {}
	for linha in _linhas:
		for entrada in linha[4].split("|"):
			var partes := entrada.split(":")
			var condicao := partes[0]
			assert_true(
				ITENS_POR_CONDICAO.has(condicao),
				"Condição desconhecida em '%s': %s" % [linha[0], condicao]
			)
			if partes.size() > 1:
				assert_eq(partes[1], "ou", "Modificador inválido em '%s': %s" % [linha[0], entrada])
				alternativos[condicao] = alternativos.get(condicao, 0) + 1
			else:
				obrigatorios[condicao] = obrigatorios.get(condicao, 0) + 1

	for condicao in ITENS_POR_CONDICAO:
		var n_alternativos: int = alternativos.get(condicao, 0)
		assert_ne(n_alternativos, 1, "'%s' tem um ingrediente ':ou' sozinho" % condicao)
		var total: int = obrigatorios.get(condicao, 0) + mini(n_alternativos, 1)
		assert_eq(total, ITENS_POR_CONDICAO[condicao], "Quantidade errada em '%s'" % condicao)
