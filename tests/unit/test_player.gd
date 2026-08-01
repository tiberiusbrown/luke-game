extends GutTest

var dungeon_level: DungeonLevel
var player: DungeonPlayer


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)
	player = DungeonPlayer.new()
	dungeon_level.add_child(player)
	_set_up_test_map()
	_place_player(Vector2i(2, 2))


func test_move_advances_exactly_one_cell_and_animates_to_center() -> void:
	var start_position: Vector2 = player.position
	var target_cell: Vector2i = player.get_current_cell() + Vector2i(1, 0)
	var target_position: Vector2 = dungeon_level.cell_to_world(target_cell)

	assert_true(player.try_move(Vector2i(1, 0)))
	assert_eq(player.get_current_cell(), target_cell)
	assert_eq(player.position, start_position)
	assert_true(player.is_moving)

	await get_tree().create_timer(DungeonPlayer.MOVE_DURATION + 0.05).timeout

	assert_eq(player.position, target_position)
	assert_false(player.is_moving)


func test_blocked_move_does_not_change_cell_or_position() -> void:
	var start_cell: Vector2i = player.get_current_cell()
	var start_position: Vector2 = player.position
	dungeon_level.tiles[start_cell.y][start_cell.x + 1] = DungeonLevel.WALL

	assert_false(player.try_move(Vector2i(1, 0)))
	assert_eq(player.get_current_cell(), start_cell)
	assert_eq(player.position, start_position)
	assert_false(player.is_moving)


func test_diagonal_move_is_not_a_valid_turn() -> void:
	var start_cell: Vector2i = player.get_current_cell()

	assert_false(player.try_move(Vector2i(1, 1)))
	assert_eq(player.get_current_cell(), start_cell)


func test_key_echo_does_not_start_an_extra_move() -> void:
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_RIGHT
	key_event.pressed = true
	player._unhandled_input(key_event)

	var echo_event: InputEventKey = InputEventKey.new()
	echo_event.keycode = KEY_RIGHT
	echo_event.pressed = true
	echo_event.echo = true
	player._unhandled_input(echo_event)

	assert_eq(player.get_current_cell(), Vector2i(3, 2))


func _set_up_test_map() -> void:
	dungeon_level.tiles.clear()
	for y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for _x: int in range(DungeonLevel.GRID_WIDTH):
			row.append(DungeonLevel.FLOOR)
		dungeon_level.tiles.append(row)


func _place_player(cell: Vector2i) -> void:
	player.current_cell = cell
	player.position = dungeon_level.cell_to_world(cell)
