class_name MazeGrid
extends RefCounted
## Grade de células de um andar: cada célula é livre ou bloqueada. É só dado,
## sem cena, então a busca em largura e os testes rodam sem tela.
##
## Tudo que está fora da grade conta como bloqueado.

## Lado de uma célula em pixels (o mesmo tile de 32 x 32 do jogo).
const TILE_SIZE := 32

var width: int
var height: int

## 1 = bloqueada, 0 = livre. Indexada por `y * width + x`.
var _blocked: PackedByteArray


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	_blocked = PackedByteArray()
	_blocked.resize(width * height)


## Centro da célula em pixels, no espaço do andar.
static func cell_to_position(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE


## Célula que contém o ponto (em pixels, no espaço do andar).
static func position_to_cell(point: Vector2) -> Vector2i:
	return Vector2i((point / TILE_SIZE).floor())


func is_inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func is_blocked(cell: Vector2i) -> bool:
	if not is_inside(cell):
		return true
	return _blocked[cell.y * width + cell.x] == 1


func is_free(cell: Vector2i) -> bool:
	return not is_blocked(cell)


## Se a célula está na borda da grade (onde ficam as paredes do andar).
func is_border(cell: Vector2i) -> bool:
	return (
		is_inside(cell)
		and (cell.x == 0 or cell.y == 0 or cell.x == width - 1 or cell.y == height - 1)
	)


## Bloqueia ou libera uma célula. Células fora da grade são ignoradas.
func set_blocked(cell: Vector2i, blocked: bool = true) -> void:
	if is_inside(cell):
		_blocked[cell.y * width + cell.x] = 1 if blocked else 0


## Bloqueia todas as células da borda da grade.
func block_border() -> void:
	for x in width:
		set_blocked(Vector2i(x, 0))
		set_blocked(Vector2i(x, height - 1))
	for y in height:
		set_blocked(Vector2i(0, y))
		set_blocked(Vector2i(width - 1, y))


## Todas as células livres, em ordem de linha.
func free_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in height:
		for x in width:
			if _blocked[y * width + x] == 0:
				result.append(Vector2i(x, y))
	return result


## Tamanho da grade em pixels.
func pixel_size() -> Vector2i:
	return Vector2i(width, height) * TILE_SIZE
