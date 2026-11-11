class_name Room
extends Node2D
## O labirinto de um andar. Pede o mapa ao `MazeGenerator` e desenha o
## resultado num `TileMapLayer` com o tileset da região. A geração só acontece
## quando `generate()` é chamado (na troca de andar), nunca a cada quadro.

## Emitido quando um andar novo foi gerado e desenhado.
signal generated(layout: MazeLayout)

## Parâmetros da geração (dimensões, obstáculos, entidades e ingredientes).
## Se ficar vazio, usa os valores padrão de `MazeParams`.
@export var params: MazeParams

## Mapa do andar atual. Nulo antes da primeira geração.
var layout: MazeLayout

@onready var _tiles: TileMapLayer = $Tiles


func _ready() -> void:
	if params == null:
		params = MazeParams.new()


## Gera e desenha um andar da região. Com `random_seed` diferente de
## `MazeGenerator.NO_SEED` o mapa é reproduzível.
func generate(region: String, random_seed: int = MazeGenerator.NO_SEED) -> MazeLayout:
	layout = MazeGenerator.generate(params, random_seed)
	_draw_layout(layout, region)
	generated.emit(layout)
	return layout


## Retângulo do andar em pixels (para os limites da câmera).
func bounds() -> Rect2i:
	return Rect2i(Vector2i.ZERO, layout.grid.pixel_size())


## Centro da célula em pixels, no espaço do andar.
func cell_to_position(cell: Vector2i) -> Vector2:
	return MazeGrid.cell_to_position(cell)


func _draw_layout(map: MazeLayout, region: String) -> void:
	_tiles.clear()
	_tiles.tile_set = RegionTileSet.for_region(region)
	var grid := map.grid
	for y in grid.height:
		for x in grid.width:
			var cell := Vector2i(x, y)
			var tile := RegionTileSet.FLOOR_TILE
			if grid.is_blocked(cell):
				tile = (
					RegionTileSet.WALL_TILE if grid.is_border(cell) else RegionTileSet.BARRIER_TILE
				)
			_tiles.set_cell(cell, RegionTileSet.source_for(region, tile), tile)
	_tiles.set_cell(map.exit_cell, RegionTileSet.SOURCE_ID, RegionTileSet.EXIT_TILE)
