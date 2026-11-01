extends GutTest
## Confere as regiões: os ids batem com o CSV e cada uma tem o tileset de
## 128 x 32 (quatro tiles de 32 x 32).


func test_region_ids_match_the_csv() -> void:
	var from_csv := []
	for ingredient in IngredientData.get_all_ingredients():
		if ingredient.region not in from_csv:
			from_csv.append(ingredient.region)
	from_csv.sort()
	var ids := Regions.IDS.duplicate()
	ids.sort()
	assert_eq(ids, from_csv)


func test_every_region_has_a_display_name() -> void:
	for region in Regions.IDS:
		assert_true(Regions.NAMES.has(region), "Falta o nome de %s" % region)
		assert_ne(Regions.display_name(region), region)
	assert_eq(Regions.display_name("campos_rios"), "Campos e Rios")
	assert_eq(Regions.display_name("desconhecida"), "desconhecida")


func test_every_region_has_a_128_by_32_tileset() -> void:
	for region in Regions.IDS:
		var texture: Texture2D = load(Regions.tileset_path(region))
		assert_not_null(texture, "Falta o tileset de %s" % region)
		assert_eq(texture.get_size(), Vector2(128, 32), "Tamanho do tileset de %s" % region)


func test_regions_have_different_tilesets() -> void:
	var seen := {}
	for region in Regions.IDS:
		var image: Image = (load(Regions.tileset_path(region)) as Texture2D).get_image()
		seen[image.get_data().hex_encode()] = true
	assert_eq(seen.size(), Regions.IDS.size())


func test_tileset_has_collision_only_on_wall_and_barrier() -> void:
	var tile_set := RegionTileSet.for_region(Regions.CAATINGA)
	assert_eq(tile_set.tile_size, Vector2i(32, 32))
	assert_eq(tile_set.get_physics_layers_count(), 1)
	var source: TileSetAtlasSource = tile_set.get_source(RegionTileSet.SOURCE_ID)
	var solid := {
		RegionTileSet.FLOOR_TILE: 0,
		RegionTileSet.WALL_TILE: 1,
		RegionTileSet.BARRIER_TILE: 1,
		RegionTileSet.EXIT_TILE: 0,
	}
	for tile: Vector2i in solid:
		var data := source.get_tile_data(tile, 0)
		assert_eq(data.get_collision_polygons_count(0), solid[tile], "Colisão do tile %s" % tile)


func test_tileset_is_cached_per_region() -> void:
	assert_same(
		RegionTileSet.for_region(Regions.CERRADO), RegionTileSet.for_region(Regions.CERRADO)
	)
	assert_ne(RegionTileSet.for_region(Regions.CERRADO), RegionTileSet.for_region(Regions.LITORAL))
