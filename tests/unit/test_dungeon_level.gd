extends GutTest

var dungeon_level: DungeonLevel


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)


func test_cell_to_world_returns_cell_center() -> void:
	assert_eq(dungeon_level.cell_to_world(Vector2i(0, 0)), Vector2(16.0, 16.0))
	assert_eq(dungeon_level.cell_to_world(Vector2i(3, 5)), Vector2(112.0, 176.0))


func test_world_to_cell_maps_positions_to_grid_cells() -> void:
	assert_eq(dungeon_level.world_to_cell(Vector2(0.0, 0.0)), Vector2i(0, 0))
	assert_eq(dungeon_level.world_to_cell(Vector2(127.9, 64.0)), Vector2i(3, 2))

