class_name MazeGenerator
extends RefCounted
## Gera o labirinto de um andar: borda, barreiras aleatórias, entrada, porta de
## saída e as posições de ingredientes e criaturas. Cada candidato é validado
## com a busca em largura (`GridBfs`) e, se o mapa não servir, gera outro.
##
## Só roda na troca de andar, nunca a cada quadro. A geração depende só dos
## parâmetros e da semente, então dá para testar sem cena.

## Semente "nenhuma": cada chamada sorteia um mapa novo.
const NO_SEED := -1
## Tentativas com barreiras antes de cair no andar aberto, sem barreiras.
const MAX_ATTEMPTS := 50
const MIN_BARRIER_LENGTH := 2
const MAX_BARRIER_LENGTH := 6
## Passos mínimos da entrada até a saída (reduzidos em grades pequenas).
const MIN_EXIT_STEPS := 8
## Passos mínimos da entrada e da saída até uma criatura.
const MIN_CREATURE_ENTRY_STEPS := 6
const MIN_CREATURE_EXIT_STEPS := 3


## Gera um andar com os parâmetros dados. Com `random_seed` diferente de
## `NO_SEED` o resultado é sempre o mesmo para a mesma semente.
static func generate(params: MazeParams, random_seed: int = NO_SEED) -> MazeLayout:
	var rng := RandomNumberGenerator.new()
	if random_seed == NO_SEED:
		rng.randomize()
	else:
		rng.seed = random_seed
	var used_seed := rng.seed

	var layout: MazeLayout = null
	for attempt in MAX_ATTEMPTS:
		layout = _try_generate(params, params.obstacles, rng)
		if layout != null:
			break
	if layout == null:
		# Sem barreiras o andar sempre tem solução.
		layout = _try_generate(params, 0, rng)
	layout.random_seed = used_seed
	return layout


## Uma tentativa. Devolve null se o mapa sorteado não servir.
static func _try_generate(
	params: MazeParams, obstacles: int, rng: RandomNumberGenerator
) -> MazeLayout:
	var grid := MazeGrid.new(params.width, params.height)
	grid.block_border()
	for i in obstacles:
		_place_barrier(grid, rng)

	var free := grid.free_cells()
	if free.size() < 2 + params.items:
		return null

	var layout := MazeLayout.new()
	layout.grid = grid
	layout.entry_cell = free[rng.randi_range(0, free.size() - 1)]

	var from_entry := GridBfs.distances(grid, layout.entry_cell)
	var farthest := 0
	for steps: int in from_entry.values():
		farthest = maxi(farthest, steps)
	if farthest == 0:
		return null
	var min_exit_steps := mini(MIN_EXIT_STEPS, farthest)
	var exit_options: Array[Vector2i] = []
	for cell: Vector2i in from_entry:
		if from_entry[cell] >= min_exit_steps:
			exit_options.append(cell)
	layout.exit_cell = exit_options[rng.randi_range(0, exit_options.size() - 1)]

	var item_options: Array[Vector2i] = []
	for cell: Vector2i in from_entry:
		if cell != layout.entry_cell and cell != layout.exit_cell:
			item_options.append(cell)
	if item_options.size() < params.items:
		return null
	_shuffle(item_options, rng)
	layout.item_cells.assign(item_options.slice(0, params.items))

	_place_creatures(layout, params.entities, from_entry, rng)
	return layout


## Sorteia um trecho de parede horizontal ou vertical dentro do andar, deixando
## livre a faixa junto da borda.
static func _place_barrier(grid: MazeGrid, rng: RandomNumberGenerator) -> void:
	var length := rng.randi_range(MIN_BARRIER_LENGTH, MAX_BARRIER_LENGTH)
	var horizontal := rng.randi_range(0, 1) == 0
	var last_x := grid.width - 3
	var last_y := grid.height - 3
	if horizontal:
		var start := Vector2i(rng.randi_range(2, last_x - length + 1), rng.randi_range(2, last_y))
		for i in length:
			grid.set_blocked(start + Vector2i(i, 0))
	else:
		var start := Vector2i(rng.randi_range(2, last_x), rng.randi_range(2, last_y - length + 1))
		for i in length:
			grid.set_blocked(start + Vector2i(0, i))


## Reserva as posições das criaturas. Uma célula só serve se ficar longe da
## entrada e da saída e se, com ela bloqueada, a entrada ainda alcançar a saída
## e todos os ingredientes: criatura parada nunca fecha o único caminho.
static func _place_creatures(
	layout: MazeLayout, count: int, from_entry: Dictionary, rng: RandomNumberGenerator
) -> void:
	if count <= 0:
		return
	var grid := layout.grid
	var from_exit := GridBfs.distances(grid, layout.exit_cell)
	var taken := {}
	for cell in layout.item_cells:
		taken[cell] = true
	var options: Array[Vector2i] = []
	for cell: Vector2i in from_entry:
		if taken.has(cell) or cell == layout.entry_cell or cell == layout.exit_cell:
			continue
		if (
			from_entry[cell] >= MIN_CREATURE_ENTRY_STEPS
			and from_exit[cell] >= MIN_CREATURE_EXIT_STEPS
		):
			options.append(cell)
	_shuffle(options, rng)

	var required: Array[Vector2i] = [layout.exit_cell]
	required.append_array(layout.item_cells)
	for cell in options:
		if layout.creature_cells.size() >= count:
			break
		grid.set_blocked(cell)
		if _all_reachable(grid, layout.entry_cell, required):
			layout.creature_cells.append(cell)
		else:
			grid.set_blocked(cell, false)
	# A grade entregue não guarda as criaturas como parede.
	for cell in layout.creature_cells:
		grid.set_blocked(cell, false)


static func _all_reachable(grid: MazeGrid, from: Vector2i, targets: Array[Vector2i]) -> bool:
	var reachable := GridBfs.distances(grid, from)
	for target in targets:
		if not reachable.has(target):
			return false
	return true


## Embaralha com o gerador dado (o `Array.shuffle` usa o sorteio global e
## quebraria a semente).
static func _shuffle(cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(cells.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := cells[i]
		cells[i] = cells[j]
		cells[j] = swap
