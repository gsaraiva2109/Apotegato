class_name RegionTileSet
extends RefCounted
## Monta o TileSet de uma região a partir do PNG de 128 x 32 dela
## (`assets/art/regions/<id>/tileset.png`). São quatro tiles de 32 x 32, na
## ordem abaixo; só a parede e a barreira têm colisão.
##
## Água animada: se a região tiver `water.png` (128 x 32 * quadros, os quadros de
## cada tile empilhados na coluna dele), os tiles que têm algo desenhado nele
## viram água animada, numa segunda fonte (`WATER_SOURCE_ID`) com as mesmas
## coordenadas e a mesma colisão. `source_for()` diz qual fonte usar em cada tile.
##
## Os TileSets ficam em cache, então trocar de andar na mesma região não monta
## tudo de novo.

const FLOOR_TILE := Vector2i(0, 0)
const WALL_TILE := Vector2i(1, 0)
const BARRIER_TILE := Vector2i(2, 0)
const EXIT_TILE := Vector2i(3, 0)

## Id da fonte (atlas) dentro de cada TileSet montado aqui.
const SOURCE_ID := 0

## Id da fonte com os tiles de água animada.
const WATER_SOURCE_ID := 1
## Quanto dura cada quadro da água, em segundos.
const WATER_FRAME_SECONDS := 0.35

static var _cache: Dictionary = {}
static var _water_tiles: Dictionary = {}


## TileSet da região. Se o id for desconhecido, usa o da primeira região.
static func for_region(region: String) -> TileSet:
	if not Regions.is_valid(region):
		push_warning("RegionTileSet: região desconhecida '%s'" % region)
		region = Regions.IDS[0]
	if not _cache.has(region):
		var tile_set := _build(load(Regions.tileset_path(region)))
		_water_tiles[region] = _add_water(tile_set, region)
		_cache[region] = tile_set
	return _cache[region]


## Fonte do TileSet onde está o tile nessa região: a da água, se ele for água
## animada ali, ou a comum.
static func source_for(region: String, tile: Vector2i) -> int:
	for_region(region)
	var water: Array = _water_tiles.get(region, [])
	return WATER_SOURCE_ID if tile in water else SOURCE_ID


## Esvazia o cache (usado nos testes).
static func clear_cache() -> void:
	_cache.clear()
	_water_tiles.clear()


static func _build(texture: Texture2D) -> TileSet:
	var tile_size := Vector2i(MazeGrid.TILE_SIZE, MazeGrid.TILE_SIZE)
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_physics_layer()

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = tile_size
	# A fonte precisa estar no TileSet antes de receber colisão nos tiles.
	tile_set.add_source(source, SOURCE_ID)

	var half := Vector2(tile_size) / 2.0
	var square := PackedVector2Array(
		[Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]
	)
	for tile in [FLOOR_TILE, WALL_TILE, BARRIER_TILE, EXIT_TILE]:
		source.create_tile(tile)
	# A parede é um quadrado inteiro (a borda do andar não pode ter frestas); a
	# barreira segue o desenho, para o gato só esbarrar onde ela aparece.
	var image := texture.get_image()
	var barrier_image := image.get_region(Rect2i(BARRIER_TILE * tile_size, tile_size))
	var shapes := {WALL_TILE: [square], BARRIER_TILE: silhouette_polygons(barrier_image)}
	for tile: Vector2i in shapes:
		var data := source.get_tile_data(tile, 0)
		for index in shapes[tile].size():
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, index, shapes[tile][index])
	return tile_set


## Polígonos convexos, centrados no tile, que cobrem os pixels visíveis (não
## transparentes) da imagem. Imagem toda opaca dá um quadrado; imagem toda
## transparente também (cai no quadrado para a barreira nunca sumir).
static func silhouette_polygons(tile_image: Image) -> Array[PackedVector2Array]:
	var size := tile_image.get_size()
	var half := Vector2(size) / 2.0
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(tile_image, 0.1)
	var result: Array[PackedVector2Array] = []
	for outline in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, size), 1.0):
		var pieces := Geometry2D.decompose_polygon_in_convex(outline)
		if pieces.is_empty():
			pieces = [Geometry2D.convex_hull(outline)]
		for piece in pieces:
			var centered := PackedVector2Array()
			for point in piece:
				centered.append(point - half)
			result.append(centered)
	if result.is_empty():
		result.append(
			PackedVector2Array(
				[
					Vector2(-half.x, -half.y),
					Vector2(half.x, -half.y),
					half,
					Vector2(-half.x, half.y)
				]
			)
		)
	return result


## Cria a fonte da água animada, se a região tiver `water.png`. Devolve os tiles
## que viraram água.
static func _add_water(tile_set: TileSet, region: String) -> Array[Vector2i]:
	var water: Array[Vector2i] = []
	var path := Regions.water_path(region)
	if not ResourceLoader.exists(path):
		return water
	var texture := load(path) as Texture2D
	var tile_size := tile_set.tile_size
	var frames := texture.get_height() / tile_size.y
	if frames < 2 or texture.get_width() != tile_size.x * 4:
		push_warning("RegionTileSet: %s deveria ter 128 px de largura e 2 ou mais quadros" % path)
		return water
	var image := texture.get_image()
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = tile_size
	tile_set.add_source(source, WATER_SOURCE_ID)
	var half := Vector2(tile_size) / 2.0
	var square := PackedVector2Array(
		[Vector2(-half.x, -half.y), Vector2(half.x, -half.y), half, Vector2(-half.x, half.y)]
	)
	for tile in [WALL_TILE, BARRIER_TILE]:
		var frame_rect := Rect2i(tile * tile_size, tile_size)
		if image.get_region(frame_rect).is_invisible():
			continue
		source.create_tile(tile)
		source.set_tile_animation_columns(tile, 1)
		source.set_tile_animation_frames_count(tile, frames)
		for frame in frames:
			source.set_tile_animation_frame_duration(tile, frame, WATER_FRAME_SECONDS)
		var data := source.get_tile_data(tile, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
		water.append(tile)
	return water
