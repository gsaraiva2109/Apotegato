class_name GridBfs
extends RefCounted
## Busca em largura (BFS) sobre um `MazeGrid`, andando nas quatro direções.
## Serve para validar o andar (entrada, saída e ingredientes alcançáveis) e
## para as criaturas acharem o caminho até o gato sem atravessar paredes.

const DIRECTIONS: Array[Vector2i] = [
	Vector2i.RIGHT,
	Vector2i.LEFT,
	Vector2i.DOWN,
	Vector2i.UP,
]


## Distância em passos de `start` até cada célula alcançável (inclusive o
## próprio `start`, com 0). `max_steps` limita a busca; negativo = sem limite.
## Devolve um dicionário vazio se `start` estiver bloqueada.
static func distances(grid: MazeGrid, start: Vector2i, max_steps: int = -1) -> Dictionary:
	var result := {}
	if grid.is_blocked(start):
		return result
	result[start] = 0
	var queue: Array[Vector2i] = [start]
	var head := 0
	while head < queue.size():
		var current := queue[head]
		head += 1
		var steps: int = result[current]
		if max_steps >= 0 and steps >= max_steps:
			continue
		for direction in DIRECTIONS:
			var next := current + direction
			if grid.is_blocked(next) or result.has(next):
				continue
			result[next] = steps + 1
			queue.append(next)
	return result


## Se existe caminho livre de `from` até `to`.
static func is_reachable(grid: MazeGrid, from: Vector2i, to: Vector2i) -> bool:
	return distances(grid, from).has(to)


## Todas as células alcançáveis a partir de `start`.
static func reachable_cells(grid: MazeGrid, start: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(distances(grid, start).keys())
	return result


## Menor caminho de `from` até `to`, incluindo as duas pontas. Vazio se não
## houver caminho (ou se passar de `max_steps`; negativo = sem limite).
static func path(
	grid: MazeGrid, from: Vector2i, to: Vector2i, max_steps: int = -1
) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if grid.is_blocked(from) or grid.is_blocked(to):
		return result
	var came_from := {from: from}
	var depth := {from: 0}
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size() and not came_from.has(to):
		var current := queue[head]
		head += 1
		if max_steps >= 0 and depth[current] >= max_steps:
			continue
		for direction in DIRECTIONS:
			var next := current + direction
			if grid.is_blocked(next) or came_from.has(next):
				continue
			came_from[next] = current
			depth[next] = depth[current] + 1
			queue.append(next)
	if not came_from.has(to):
		return result
	var cell := to
	while cell != from:
		result.push_front(cell)
		cell = came_from[cell]
	result.push_front(from)
	return result
