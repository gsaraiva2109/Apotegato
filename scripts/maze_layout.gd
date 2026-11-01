class_name MazeLayout
extends RefCounted
## Resultado de uma geração: a grade e os lugares reservados nela. Todas as
## células aqui são alcançáveis a partir da entrada.

var grid: MazeGrid
## Célula onde o gato aparece.
var entry_cell: Vector2i
## Célula da porta de saída.
var exit_cell: Vector2i
## Células reservadas para os ingredientes.
var item_cells: Array[Vector2i] = []
## Células reservadas para as criaturas, longe da entrada e da saída.
var creature_cells: Array[Vector2i] = []
## Semente usada. Passando de novo no gerador, o mesmo mapa sai igual.
var random_seed: int = 0
