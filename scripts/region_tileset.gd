class_name RegionTileSet
extends RefCounted
## Monta o TileSet de uma região a partir do PNG de 128 x 32 dela
## (`assets/art/regions/<id>/tileset.png`). São quatro tiles de 32 x 32, na
## ordem abaixo; só a parede e a barreira têm colisão.
##
## Os TileSets ficam em cache, então trocar de andar na mesma região não monta
## tudo de novo.

const FLOOR_TILE := Vector2i(0, 0)
const WALL_TILE := Vector2i(1, 0)
const BARRIER_TILE := Vector2i(2, 0)
const EXIT_TILE := Vector2i(3, 0)

## Id da fonte (atlas) dentro de cada TileSet montado aqui.
const SOURCE_ID := 0

static var _cache: Dictionary = {}


## TileSet da região. Se o id for desconhecido, usa o da primeira região.
static func for_region(region: String) -> TileSet:
	if not Regions.is_valid(region):
		push_warning("RegionTileSet: região desconhecida '%s'" % region)
		region = Regions.IDS[0]
	if not _cache.has(region):
		_cache[region] = _build(load(Regions.tileset_path(region)))
	return _cache[region]


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
	for tile in [WALL_TILE, BARRIER_TILE]:
		var data := source.get_tile_data(tile, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	return tile_set
