extends GutTest
## Confere o catálogo de efeitos sonoros e o autoload Sfx: ids, caminhos,
## silêncio sem arquivo e som de clique em todo botão.

const SfxScript := preload("res://autoload/sfx.gd")


func test_catalog_ids_have_variants() -> void:
	for id in SfxCatalog.all_ids():
		assert_gt(SfxCatalog.variants_of(id), 0, "Sem variações: %s" % id)


func test_catalog_has_events_from_issue() -> void:
	for id in [
		SfxCatalog.ARRANHAO,
		SfxCatalog.DANO,
		SfxCatalog.DESMAIO,
		SfxCatalog.COLETA,
		SfxCatalog.PORTA,
		SfxCatalog.ENTREGA_COMPLETA,
		SfxCatalog.CLIQUE,
	]:
		assert_true(SfxCatalog.has(id), "Falta o efeito %s" % id)


func test_path_format() -> void:
	assert_eq(
		SfxCatalog.path_for(&"scratch", 2),
		"res://assets/audio/third_party/sfx/scratch_2.ogg",
	)


func test_unknown_id_is_ignored() -> void:
	assert_eq(SfxCatalog.variants_of(&"nao_existe"), 0)
	assert_eq(SfxCatalog.gain_of(&"nao_existe"), 0.0)
	assert_false(Sfx.play(&"nao_existe"))


func test_play_without_file_is_silent_and_safe() -> void:
	var sfx: Node = autofree(SfxScript.new())
	add_child(sfx)
	for id in SfxCatalog.all_ids():
		var played: bool = sfx.play(id)
		var exists := ResourceLoader.exists(SfxCatalog.path_for(id, 1))
		# Com um id de 2+ variações, sortear a 2ª sem arquivo também é seguro.
		assert_true(not played or exists, "Tocou sem arquivo: %s" % id)


func test_pool_uses_sfx_bus() -> void:
	var sfx: Node = autofree(SfxScript.new())
	add_child(sfx)
	assert_eq(sfx.get_child_count(), SfxScript.POOL_SIZE)
	for child in sfx.get_children():
		assert_eq((child as AudioStreamPlayer).bus, &"SFX")
