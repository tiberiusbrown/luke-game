extends GutTest

var dungeon_level: DungeonLevel
var player: DungeonPlayer


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)
	dungeon_level._clear_enemies()
	dungeon_level.clear_pickups()
	_set_up_test_map()

	player = DungeonPlayer.new()
	dungeon_level.add_child(player)
	_place_player(Vector2i(5, 5))
	dungeon_level.visible_cells.clear()
	dungeon_level.known_cells.clear()
	dungeon_level.refresh_visibility()


func test_player_light_uses_the_five_cell_radius_and_remembers_lit_cells() -> void:
	var edge_cell: Vector2i = Vector2i(10, 5)
	var outside_cell: Vector2i = Vector2i(11, 5)

	assert_true(dungeon_level.is_cell_visible(edge_cell))
	assert_true(dungeon_level.is_cell_known(edge_cell))
	assert_false(dungeon_level.is_cell_visible(outside_cell))
	assert_false(dungeon_level.is_cell_known(outside_cell))

	_place_player(Vector2i(0, 0))
	dungeon_level.refresh_visibility()

	assert_false(dungeon_level.is_cell_visible(edge_cell))
	assert_true(dungeon_level.is_cell_known(edge_cell))


func test_wall_is_lit_but_blocks_the_light_path() -> void:
	dungeon_level.tiles[5][6] = DungeonLevel.WALL
	dungeon_level.visible_cells.clear()
	dungeon_level.known_cells.clear()
	dungeon_level.refresh_visibility()

	assert_true(dungeon_level.is_cell_visible(Vector2i(6, 5)))
	assert_false(dungeon_level.is_cell_visible(Vector2i(7, 5)))
	assert_false(dungeon_level.is_cell_known(Vector2i(7, 5)))


func test_discovered_pickups_remain_visible_but_dimmed_outside_current_light() -> void:
	var pickup: ItemPickup = dungeon_level.spawn_pickup("Ancient Coin", Vector2i(10, 5))

	assert_true(pickup.is_known)
	assert_true(pickup.is_lit)
	assert_true(pickup.visible)

	_place_player(Vector2i(0, 0))
	dungeon_level.refresh_visibility()

	assert_true(pickup.is_known)
	assert_false(pickup.is_lit)
	assert_true(pickup.visible)


func test_entities_are_hidden_when_their_cells_are_not_lit() -> void:
	var enemy: DungeonEnemy = dungeon_level.spawn_enemy(ZombieEnemy.new(), Vector2i(10, 5))

	assert_true(enemy.visible)

	_place_player(Vector2i(0, 0))
	dungeon_level.refresh_visibility()

	assert_false(enemy.visible)


func test_moving_the_player_refreshes_the_light_after_the_move_finishes() -> void:
	assert_true(dungeon_level.is_cell_visible(Vector2i(10, 5)))

	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout

	assert_eq(player.current_cell, Vector2i(6, 5))
	assert_true(dungeon_level.is_cell_visible(Vector2i(11, 5)))
	assert_true(dungeon_level.is_cell_known(Vector2i(10, 5)))


func _set_up_test_map() -> void:
	dungeon_level.tiles.clear()
	for _y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for _x: int in range(DungeonLevel.GRID_WIDTH):
			row.append(DungeonLevel.FLOOR)
		dungeon_level.tiles.append(row)


func _place_player(cell: Vector2i) -> void:
	player.current_cell = cell
	player.position = dungeon_level.cell_to_world(cell)
