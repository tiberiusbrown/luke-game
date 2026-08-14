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


func test_booby_trap_deals_one_heart_when_activated() -> void:
	var trap: BoobyTrap = dungeon_level.spawn_booby_trap(Vector2i(3, 2))
	var starting_hearts: int = player.health.current_hearts

	assert_eq(trap.activate(player), BoobyTrap.DAMAGE_HEARTS)
	assert_eq(player.health.current_hearts, starting_hearts - 1)
	assert_true(trap.is_activated)


func test_booby_trap_cannot_be_activated_again() -> void:
	var trap: BoobyTrap = dungeon_level.spawn_booby_trap(Vector2i(3, 2))

	assert_eq(trap.activate(player), 1)
	assert_eq(trap.activate(player), 0)
	assert_eq(player.health.current_hearts, DungeonPlayer.MAX_HEARTS - 1)


func test_moving_onto_booby_trap_activates_it_once() -> void:
	var trap: BoobyTrap = dungeon_level.spawn_booby_trap(Vector2i(3, 2))

	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout
	assert_eq(player.health.current_hearts, DungeonPlayer.MAX_HEARTS - 1)
	assert_true(trap.is_activated)

	assert_true(player.try_move(Vector2i(-1, 0)))
	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout
	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout
	assert_eq(player.health.current_hearts, DungeonPlayer.MAX_HEARTS - 1)


func test_generated_dungeon_contains_one_shot_booby_traps() -> void:
	dungeon_level.generate()

	assert_eq(dungeon_level.booby_traps.size(), DungeonLevel.BOOBY_TRAP_COUNT)
	for trap: BoobyTrap in dungeon_level.booby_traps:
		assert_true(dungeon_level.is_walkable(trap.cell))
		assert_ne(trap.cell, dungeon_level.get_start_cell())
		assert_false(trap.is_activated)


func _set_up_test_map() -> void:
	dungeon_level.castle_area = Rect2i()
	dungeon_level._clear_enemies()
	dungeon_level.clear_booby_traps()
	dungeon_level.tiles.clear()
	for y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for _x: int in range(DungeonLevel.GRID_WIDTH):
			row.append(DungeonLevel.FLOOR)
		dungeon_level.tiles.append(row)


func _place_player(cell: Vector2i) -> void:
	player.current_cell = cell
	player.position = dungeon_level.cell_to_world(cell)
