extends GutTest
## Confere o catálogo das criaturas: leitura do CSV, criaturas liberadas por
## região e andar e o sorteio por peso (com semente fixa).

const TEST_CSV := "user://test_criaturas.csv"
const HEADER := "id,nome,regiao,dano,golpes,velocidade,andar_minimo,peso\n"

var _catalog: CreatureCatalog
var _rng: RandomNumberGenerator


func before_each() -> void:
	_catalog = CreatureCatalog.new()
	_rng = RandomNumberGenerator.new()
	_rng.seed = 12345


func after_each() -> void:
	if FileAccess.file_exists(TEST_CSV):
		DirAccess.remove_absolute(TEST_CSV)


func _write(body: String) -> void:
	var file := FileAccess.open(TEST_CSV, FileAccess.WRITE)
	file.store_string(body)
	file.close()


func _load_sample() -> void:
	_write(
		(
			HEADER
			+ "fraca,Fraca,cerrado,1,3,70,1,2\n"
			+ "forte,Forte,cerrado,2,4,80,3,1\n"
			+ "outra,Outra,litoral,1,3,70,1,1\n"
		)
	)
	assert_true(_catalog.load_csv(TEST_CSV))


func test_reads_every_column() -> void:
	_load_sample()
	assert_eq(_catalog.all().size(), 3)
	var strong := _catalog.get_entry("forte")
	assert_eq(strong.display_name, "Forte")
	assert_eq(strong.region, "cerrado")
	assert_eq(strong.damage, 2)
	assert_eq(strong.hits, 4)
	assert_eq(strong.speed, 80.0)
	assert_eq(strong.min_floor, 3)
	assert_eq(strong.weight, 1)
	assert_true(strong.is_strong())
	assert_false(_catalog.get_entry("fraca").is_strong())
	assert_null(_catalog.get_entry("nao_existe"))


func test_missing_file_or_wrong_header_fails() -> void:
	assert_false(_catalog.load_csv("user://nao_existe.csv"))
	_write("id,nome\nx,y\n")
	assert_false(_catalog.load_csv(TEST_CSV))
	assert_push_error("cabeçalho inesperado")
	assert_true(_catalog.all().is_empty())


func test_invalid_rows_are_skipped() -> void:
	_write(HEADER + "boa,Boa,cerrado,1,3,70,1,2\nquebrada,Quebrada\n\n")
	assert_true(_catalog.load_csv(TEST_CSV))
	assert_eq(_catalog.all().size(), 1)
	assert_push_error("linha inválida")


func test_entries_for_respects_region_and_floor() -> void:
	_load_sample()
	assert_eq(_catalog.entries_for("cerrado", 1).size(), 1, "A forte só vem no andar 3")
	assert_eq(_catalog.entries_for("cerrado", 2).size(), 1)
	assert_eq(_catalog.entries_for("cerrado", 3).size(), 2)
	assert_eq(_catalog.entries_for("litoral", 1).size(), 1)
	assert_true(_catalog.entries_for("amazonia", 9).is_empty())


func test_pick_before_the_strong_floor_is_always_the_weak_one() -> void:
	_load_sample()
	for i in 50:
		assert_eq(_catalog.pick("cerrado", 2, _rng).id, "fraca")


func test_pick_without_candidates_is_null() -> void:
	_load_sample()
	assert_null(_catalog.pick("amazonia", 1, _rng))


func test_pick_follows_the_weights() -> void:
	_load_sample()
	var strong := 0
	var total := 3000
	for i in total:
		if _catalog.pick("cerrado", 3, _rng).id == "forte":
			strong += 1
	# Pesos 2 e 1: a forte sai em cerca de 1 de cada 3.
	assert_almost_eq(float(strong) / total, 1.0 / 3.0, 0.05)


func test_pick_with_a_fixed_seed_is_repeatable() -> void:
	_load_sample()
	var first: Array[String] = []
	for i in 10:
		first.append(_catalog.pick("cerrado", 3, _rng).id)
	_rng.seed = 12345
	var second: Array[String] = []
	for i in 10:
		second.append(_catalog.pick("cerrado", 3, _rng).id)
	assert_eq(first, second)


func test_default_catalog_loads_the_game_csv() -> void:
	var catalog := CreatureCatalog.load_default()
	assert_eq(catalog.all().size(), 12)
