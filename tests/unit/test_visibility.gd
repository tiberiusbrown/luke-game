extends GutTest

var field_of_view: DungeonFieldOfView
var opaque_cells: Dictionary = {}


func before_each() -> void:
	field_of_view = DungeonFieldOfView.new(11, 11)
	opaque_cells.clear()


func test_field_of_view_stays_within_the_requested_radius() -> void:
	var visible_cells: Array[Vector2i] = field_of_view.compute(
		Vector2i(5, 5),
		5,
		Callable(self, "_is_test_cell_opaque"),
	)

	assert_true(visible_cells.has(Vector2i(5, 5)))
	assert_true(visible_cells.has(Vector2i(10, 5)))
	assert_true(visible_cells.has(Vector2i(8, 8)))
	assert_false(visible_cells.has(Vector2i(0, 4)))
	assert_false(visible_cells.has(Vector2i(9, 9)))


func test_opaque_cells_are_lit_but_cast_a_shadow_beyond_them() -> void:
	opaque_cells[Vector2i(6, 5)] = true

	var visible_cells: Array[Vector2i] = field_of_view.compute(
		Vector2i(5, 5),
		5,
		Callable(self, "_is_test_cell_opaque"),
	)

	assert_true(visible_cells.has(Vector2i(6, 5)))
	assert_false(visible_cells.has(Vector2i(7, 5)))
	assert_true(visible_cells.has(Vector2i(7, 4)))


func _is_test_cell_opaque(cell: Vector2i) -> bool:
	return opaque_cells.has(cell)
