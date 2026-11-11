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


func test_water_regions_have_animated_wall_and_barrier() -> void:
	var tile_set := RegionTileSet.for_region(Regions.CAMPOS_RIOS)
	var source := tile_set.get_source(RegionTileSet.WATER_SOURCE_ID) as TileSetAtlasSource
	assert_not_null(source, "Campos e Rios tem a fonte da água")
	for tile in [RegionTileSet.WALL_TILE, RegionTileSet.BARRIER_TILE]:
		assert_eq(
			RegionTileSet.source_for(Regions.CAMPOS_RIOS, tile), RegionTileSet.WATER_SOURCE_ID
		)
		assert_gt(source.get_tile_animation_frames_count(tile), 1, "Quadros do tile %s" % tile)
		var data := source.get_tile_data(tile, 0)
		assert_eq(data.get_collision_polygons_count(0), 1, "A água bloqueia o gato")
	assert_eq(
		RegionTileSet.source_for(Regions.CAMPOS_RIOS, RegionTileSet.FLOOR_TILE),
		RegionTileSet.SOURCE_ID
	)


func test_only_the_wall_is_water_on_the_coast() -> void:
	assert_eq(
		RegionTileSet.source_for(Regions.LITORAL, RegionTileSet.WALL_TILE),
		RegionTileSet.WATER_SOURCE_ID
	)
	assert_eq(
		RegionTileSet.source_for(Regions.LITORAL, RegionTileSet.BARRIER_TILE),
		RegionTileSet.SOURCE_ID
	)


func test_regions_without_water_use_only_the_plain_source() -> void:
	var tile_set := RegionTileSet.for_region(Regions.CERRADO)
	assert_false(tile_set.has_source(RegionTileSet.WATER_SOURCE_ID))
	assert_eq(
		RegionTileSet.source_for(Regions.CERRADO, RegionTileSet.WALL_TILE), RegionTileSet.SOURCE_ID
	)
