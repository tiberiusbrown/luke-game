extends GutTest

var dungeon_level: DungeonLevel
var player: DungeonPlayer


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)
	player = DungeonPlayer.new()
	dungeon_level.add_child(player)
	_set_up_corner_map()


func test_horizontal_input_slides_down_around_nearby_corner() -> void:
	player.position = Vector2(233.0, 199.0)
	assert_true(dungeon_level.can_stand_at(player.position))
	assert_false(dungeon_level.can_stand_at(player.position + Vector2(-2.0, 0.0)))

	player._move_with_collision_slide(Vector2(-2.0, 0.0))

	assert_eq(player.position, Vector2(233.0, 201.0))

	for _step: int in range(10):
		player._move_with_collision_slide(Vector2(-2.0, 0.0))

	assert_lt(player.position.x, 233.0)


func test_horizontal_input_slides_up_around_nearby_corner() -> void:
	player.position = Vector2(118.0, 89.0)
	assert_true(dungeon_level.can_stand_at(player.position))
	assert_false(dungeon_level.can_stand_at(player.position + Vector2(2.0, 0.0)))

	player._move_with_collision_slide(Vector2(2.0, 0.0))

	assert_eq(player.position, Vector2(118.0, 87.0))


func _set_up_corner_map() -> void:
	dungeon_level.tiles.clear()
	for y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for x: int in range(DungeonLevel.GRID_WIDTH):
			var tile: int = DungeonLevel.FLOOR
			if x >= 4 and x <= 6 and y >= 3 and y <= 5:
				tile = DungeonLevel.WALL
			row.append(tile)
		dungeon_level.tiles.append(row)
