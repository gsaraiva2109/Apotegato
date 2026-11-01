extends GutTest
## Confere a busca em largura sobre a grade: caminho existente, grade bloqueada,
## distâncias e menor caminho. Nada aqui precisa de cena.


## Monta uma grade a partir de linhas de texto: "#" é parede, o resto é livre.
func _grid(rows: Array[String]) -> MazeGrid:
	var grid := MazeGrid.new(rows[0].length(), rows.size())
	for y in rows.size():
		for x in rows[y].length():
			grid.set_blocked(Vector2i(x, y), rows[y][x] == "#")
	return grid


func test_path_exists_in_open_grid() -> void:
	var grid := _grid(["....", "....", "...."])
	assert_true(GridBfs.is_reachable(grid, Vector2i(0, 0), Vector2i(3, 2)))


func test_path_goes_around_a_wall() -> void:
	var grid := _grid(["..#..", "..#..", "....."])
	assert_true(GridBfs.is_reachable(grid, Vector2i(0, 0), Vector2i(4, 0)))
	assert_eq(GridBfs.distances(grid, Vector2i(0, 0))[Vector2i(4, 0)], 8)


func test_blocked_grid_has_no_path() -> void:
	var grid := _grid(["..#..", "..#..", "..#.."])
	assert_false(GridBfs.is_reachable(grid, Vector2i(0, 0), Vector2i(4, 0)))
	assert_false(GridBfs.distances(grid, Vector2i(0, 0)).has(Vector2i(3, 1)))


func test_blocked_start_or_target() -> void:
	var grid := _grid([".#.", "..."])
	assert_true(GridBfs.distances(grid, Vector2i(1, 0)).is_empty())
	assert_false(GridBfs.is_reachable(grid, Vector2i(0, 0), Vector2i(1, 0)))
	assert_true(GridBfs.path(grid, Vector2i(0, 0), Vector2i(1, 0)).is_empty())


func test_outside_the_grid_counts_as_blocked() -> void:
	var grid := _grid(["..", ".."])
	assert_true(grid.is_blocked(Vector2i(-1, 0)))
	assert_true(grid.is_blocked(Vector2i(2, 0)))
	assert_false(GridBfs.is_reachable(grid, Vector2i(0, 0), Vector2i(5, 5)))


func test_distances_do_not_cut_corners() -> void:
	var grid := _grid(["...", "...", "..."])
	var distances := GridBfs.distances(grid, Vector2i(0, 0))
	assert_eq(distances[Vector2i(0, 0)], 0)
	assert_eq(distances[Vector2i(1, 1)], 2, "Só anda nas quatro direções")
	assert_eq(distances[Vector2i(2, 2)], 4)


func test_max_steps_limits_the_search() -> void:
	var grid := _grid(["......"])
	var distances := GridBfs.distances(grid, Vector2i(0, 0), 2)
	assert_eq(distances.size(), 3)
	assert_false(distances.has(Vector2i(3, 0)))


func test_reachable_cells_only_lists_the_connected_area() -> void:
	var grid := _grid(["..#.", "..#."])
	var cells := GridBfs.reachable_cells(grid, Vector2i(0, 0))
	assert_eq(cells.size(), 4)
	assert_false(Vector2i(3, 0) in cells)


func test_shortest_path_has_both_ends_and_is_continuous() -> void:
	var grid := _grid(["..#..", "..#..", "....."])
	var path := GridBfs.path(grid, Vector2i(0, 0), Vector2i(4, 0))
	assert_eq(path.size(), 9)
	assert_eq(path[0], Vector2i(0, 0))
	assert_eq(path[-1], Vector2i(4, 0))
	for i in range(1, path.size()):
		assert_eq((path[i] - path[i - 1]).length_squared(), 1, "Passos de uma célula")
		assert_true(grid.is_free(path[i]))


func test_path_to_itself_is_a_single_cell() -> void:
	var grid := _grid(["..."])
	assert_eq(GridBfs.path(grid, Vector2i(1, 0), Vector2i(1, 0)), [Vector2i(1, 0)])


func test_path_respects_max_steps() -> void:
	var grid := _grid(["......"])
	assert_true(GridBfs.path(grid, Vector2i(0, 0), Vector2i(5, 0), 3).is_empty())
	assert_eq(GridBfs.path(grid, Vector2i(0, 0), Vector2i(3, 0), 3).size(), 4)


func test_cell_and_position_conversion() -> void:
	assert_eq(MazeGrid.cell_to_position(Vector2i(0, 0)), Vector2(16, 16))
	assert_eq(MazeGrid.cell_to_position(Vector2i(2, 1)), Vector2(80, 48))
	assert_eq(MazeGrid.position_to_cell(Vector2(80, 48)), Vector2i(2, 1))
	assert_eq(MazeGrid.position_to_cell(Vector2(-1, 0)), Vector2i(-1, 0))


func test_border_blocking() -> void:
	var grid := MazeGrid.new(5, 4)
	grid.block_border()
	assert_eq(grid.free_cells().size(), 3 * 2)
	assert_true(grid.is_border(Vector2i(0, 2)))
	assert_false(grid.is_border(Vector2i(1, 1)))
