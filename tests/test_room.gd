extends GutTest
## Confere a cena do labirinto: desenha o mapa gerado, usa o tileset da região
## e bloqueia o gato nas paredes.

const RoomScene := preload("res://scenes/region/room.tscn")

var _room: Room


func before_each() -> void:
	_room = autofree(RoomScene.instantiate())
	add_child(_room)
	await wait_physics_frames(1)


func _tiles() -> TileMapLayer:
	return _room.get_node("Tiles")


func test_default_params_come_from_maze_params() -> void:
	assert_not_null(_room.params)
	assert_eq(_room.params.width, 30)
	assert_eq(_room.params.height, 17)


func test_generate_draws_the_whole_floor() -> void:
	var layout := _room.generate(Regions.AMAZONIA, 1)
	assert_eq(_tiles().get_used_rect(), Rect2i(0, 0, 30, 17))
	assert_eq(_room.bounds(), Rect2i(0, 0, 960, 544))
	assert_same(_room.layout, layout)


func test_tiles_match_the_grid() -> void:
	var layout := _room.generate(Regions.CAATINGA, 2)
	var grid := layout.grid
	assert_eq(_tiles().get_cell_atlas_coords(layout.exit_cell), RegionTileSet.EXIT_TILE)
	assert_eq(_tiles().get_cell_atlas_coords(layout.entry_cell), RegionTileSet.FLOOR_TILE)
	assert_eq(_tiles().get_cell_atlas_coords(Vector2i(0, 0)), RegionTileSet.WALL_TILE)
	for cell in layout.item_cells:
		assert_eq(_tiles().get_cell_atlas_coords(cell), RegionTileSet.FLOOR_TILE)
	for y in grid.height:
		for x in grid.width:
			var cell := Vector2i(x, y)
			if grid.is_blocked(cell) and not grid.is_border(cell):
				assert_eq(_tiles().get_cell_atlas_coords(cell), RegionTileSet.BARRIER_TILE)


func test_each_region_uses_its_own_tileset() -> void:
	for region in Regions.IDS:
		_room.generate(region, 1)
		var source: TileSetAtlasSource = _tiles().tile_set.get_source(RegionTileSet.SOURCE_ID)
		assert_eq(source.texture.resource_path, Regions.tileset_path(region))


func test_generating_again_replaces_the_floor() -> void:
	_room.generate(Regions.CERRADO)
	var first := _room.layout
	_room.generate(Regions.CERRADO)
	assert_ne(_room.layout, first)
	assert_eq(_tiles().get_used_rect(), Rect2i(0, 0, 30, 17))


func test_generated_signal_carries_the_layout() -> void:
	watch_signals(_room)
	var layout := _room.generate(Regions.LITORAL, 5)
	assert_signal_emitted_with_parameters(_room, "generated", [layout])


func test_cell_to_position_is_the_tile_center() -> void:
	assert_eq(_room.cell_to_position(Vector2i(1, 1)), Vector2(48, 48))


func test_walls_stop_a_body() -> void:
	var layout := _room.generate(Regions.MATA_ATLANTICA, 3)
	var body := CharacterBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 14)
	shape.shape = rect
	body.add_child(shape)
	_room.add_child(body)
	body.position = MazeGrid.cell_to_position(layout.entry_cell)
	await wait_physics_frames(2)
	# empurra para a esquerda por mais tempo do que o andar tem de largura
	for i in 400:
		body.velocity = Vector2.LEFT * 200.0
		body.move_and_slide()
	assert_gt(body.position.x, 32.0 - 1.0, "Não atravessa a borda do andar")


func test_water_region_draws_walls_and_barriers_from_the_water_source() -> void:
	var layout := _room.generate(Regions.CAMPOS_RIOS, 1)
	var tiles := _tiles()
	assert_eq(tiles.get_cell_source_id(Vector2i(0, 0)), RegionTileSet.WATER_SOURCE_ID)
	assert_eq(tiles.get_cell_atlas_coords(Vector2i(0, 0)), RegionTileSet.WALL_TILE)
	assert_eq(tiles.get_cell_source_id(layout.entry_cell), RegionTileSet.SOURCE_ID)
	assert_eq(tiles.get_cell_source_id(layout.exit_cell), RegionTileSet.SOURCE_ID)
