extends GutTest
## Confere o data/criaturas.csv do jogo: regiões conhecidas, dano de meio ou um
## coração, números positivos e pelo menos uma criatura por região no andar 1.

var _catalog: CreatureCatalog


func before_each() -> void:
	_catalog = CreatureCatalog.load_default()


func test_has_a_weak_and_a_strong_creature_per_region() -> void:
	assert_eq(_catalog.all().size(), Regions.IDS.size() * 2)
	for region in Regions.IDS:
		var in_region := _catalog.entries_for(region, 99)
		assert_eq(in_region.size(), 2, "Duas criaturas em %s" % region)
		assert_ne(in_region[0].damage, in_region[1].damage)


func test_ids_are_unique_and_names_filled() -> void:
	var ids := []
	for entry in _catalog.all():
		assert_does_not_have(ids, entry.id, "id repetido: %s" % entry.id)
		ids.append(entry.id)
		assert_false(entry.display_name.strip_edges().is_empty(), entry.id)


func test_regions_are_known() -> void:
	for entry in _catalog.all():
		assert_true(Regions.is_valid(entry.region), "%s: região %s" % [entry.id, entry.region])


func test_damage_is_half_or_one_heart() -> void:
	for entry in _catalog.all():
		assert_between(entry.damage, 1, Hearts.HALVES_PER_HEART, "dano de %s" % entry.id)


func test_numbers_are_positive() -> void:
	for entry in _catalog.all():
		assert_gt(entry.hits, 0, "golpes de %s" % entry.id)
		assert_gt(entry.weight, 0, "peso de %s" % entry.id)
		assert_gt(entry.speed, 0.0, "velocidade de %s" % entry.id)
		assert_gte(entry.min_floor, 1, "andar mínimo de %s" % entry.id)


func test_every_region_has_a_creature_on_floor_one() -> void:
	for region in Regions.IDS:
		assert_false(
			_catalog.entries_for(region, 1).is_empty(), "Sem criatura no andar 1: %s" % region
		)


func test_weak_creatures_are_the_ones_on_floor_one() -> void:
	for region in Regions.IDS:
		for entry in _catalog.entries_for(region, 1):
			assert_false(entry.is_strong(), "%s aparece no andar 1 sendo forte" % entry.id)
