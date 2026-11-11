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
		if solid[tile] == 0:
			assert_eq(data.get_collision_polygons_count(0), 0, "Sem colisão no tile %s" % tile)
		else:
			assert_gt(data.get_collision_polygons_count(0), 0, "Colisão do tile %s" % tile)


func _polygons_area(polygons: Array[PackedVector2Array]) -> float:
	var area := 0.0
	for polygon in polygons:
		var points := polygon
		var twice := 0.0
		for i in points.size():
			var a := points[i]
			var b := points[(i + 1) % points.size()]
			twice += a.x * b.y - b.x * a.y
		area += absf(twice) / 2.0
	return area


func test_silhouette_of_an_opaque_tile_is_the_whole_square() -> void:
	var image := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var polygons := RegionTileSet.silhouette_polygons(image)
	assert_almost_eq(_polygons_area(polygons), 1024.0, 1.0)


func test_silhouette_follows_the_visible_pixels() -> void:
	var image := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	image.fill_rect(Rect2i(4, 6, 24, 20), Color.WHITE)
	var polygons := RegionTileSet.silhouette_polygons(image)
	assert_almost_eq(_polygons_area(polygons), 24.0 * 20.0, 6.0)
	for polygon in polygons:
		for point in polygon:
			assert_between(point.x, -12.5, 12.5)
			assert_between(point.y, -10.5, 10.5)


func test_silhouette_of_an_empty_tile_falls_back_to_the_square() -> void:
	var image := Image.create_empty(32, 32, false, Image.FORMAT_RGBA8)
	assert_almost_eq(_polygons_area(RegionTileSet.silhouette_polygons(image)), 1024.0, 1.0)


func test_tileset_is_cached_per_region() -> void:
	assert_same(
		RegionTileSet.for_region(Regions.CERRADO), RegionTileSet.for_region(Regions.CERRADO)
	)
	assert_ne(RegionTileSet.for_region(Regions.CERRADO), RegionTileSet.for_region(Regions.LITORAL))
