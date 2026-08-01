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


func test_w_key_is_reserved_for_the_wield_menu() -> void:
	var start_cell: Vector2i = player.get_current_cell()
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_W
	key_event.pressed = true

	player._unhandled_input(key_event)

	assert_eq(player.get_current_cell(), start_cell)


func test_moving_onto_a_pickup_adds_it_to_inventory() -> void:
	dungeon_level.clear_pickups()
	dungeon_level.spawn_pickup("Amber Potion", Vector2i(3, 2))

	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonPlayer.MOVE_DURATION + 0.05).timeout

	assert_eq(player.inventory.get_item_count("Amber Potion"), 1)
	assert_eq(dungeon_level.pickups.size(), 0)


func test_player_starts_with_ten_hearts() -> void:
	assert_eq(player.health.max_hearts, DungeonPlayer.MAX_HEARTS)
	assert_eq(player.health.current_hearts, 10)


func test_player_takes_damage_in_hearts_and_cannot_move_when_depleted() -> void:
	assert_eq(player.take_damage(3), 3)
	assert_eq(player.health.current_hearts, 7)

	assert_eq(player.take_damage(7), 7)
	assert_true(player.health.is_depleted())
	assert_false(player.try_move(Vector2i(1, 0)))


func test_moving_onto_a_weapon_pickup_does_not_wield_it() -> void:
	dungeon_level.clear_pickups()
	var weapon: WeaponData = WeaponData.new("Bone Axe", 3)
	dungeon_level.spawn_weapon(weapon, Vector2i(3, 2))

	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonPlayer.MOVE_DURATION + 0.05).timeout

	assert_null(player.inventory.get_equipped_weapon())
	assert_eq(player.get_attack_damage(), 0)
	assert_eq(player.inventory.get_weapon_attack_damage("Bone Axe"), 3)
	assert_eq(dungeon_level.pickups.size(), 0)

	assert_true(player.inventory.wield_weapon(weapon))
	assert_eq(player.inventory.get_equipped_weapon(), weapon)
	assert_eq(player.get_attack_damage(), 3)


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
