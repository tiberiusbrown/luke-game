extends GutTest

var dungeon_level: DungeonLevel
var player: DungeonPlayer
var hireling: DungeonHireling


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)
	dungeon_level._clear_enemies()
	dungeon_level.clear_pickups()
	_set_up_test_map()

	player = DungeonPlayer.new()
	dungeon_level.add_child(player)
	_place_entity(player, Vector2i(2, 2))

	hireling = dungeon_level.get_hireling()
	hireling.setup(dungeon_level, Vector2i(3, 2))
	dungeon_level.refresh_visibility()


func test_hireling_has_thirteen_hearts_and_deals_three_hearts_per_hit() -> void:
	assert_eq(hireling.health.max_hearts, 13)
	assert_eq(hireling.health.current_hearts, 13)
	assert_eq(hireling.get_attack_damage(), 3)


func test_hiring_requires_and_spends_five_ancient_coins() -> void:
	for _coin_index: int in range(DungeonLevel.HIRELING_COST - 1):
		player.inventory.add_item("Ancient Coin")

	assert_true(dungeon_level.interact_with_hireling(player.current_cell, player.inventory))
	assert_false(dungeon_level.is_hireling_hired())
	assert_eq(player.inventory.get_item_count("Ancient Coin"), DungeonLevel.HIRELING_COST - 1)

	player.inventory.add_item("Ancient Coin")
	assert_true(dungeon_level.interact_with_hireling(player.current_cell, player.inventory))
	assert_true(dungeon_level.is_hireling_hired())
	assert_true(hireling.is_hired)
	assert_eq(player.inventory.get_item_count("Ancient Coin"), 0)


func test_hired_hireling_attacks_enemies_for_three_hearts() -> void:
	hireling.hire()
	var enemy: ZombieEnemy = ZombieEnemy.new()
	enemy.hit_chance = 1.0
	dungeon_level.spawn_enemy(enemy, Vector2i(4, 2))

	assert_true(hireling.take_turn())
	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_eq(enemy.health.current_hearts, 7)


func test_hired_hireling_attacks_automatically_after_the_player_moves() -> void:
	_hire_hireling()
	var enemy: ZombieEnemy = ZombieEnemy.new()
	enemy.hit_chance = 1.0
	dungeon_level.spawn_enemy(enemy, Vector2i(4, 2))

	assert_true(player.try_move(Vector2i(0, 1)))
	await get_tree().create_timer(HitEffect.DURATION + 0.15).timeout

	assert_eq(enemy.health.current_hearts, 7)


func test_hired_hireling_follows_the_player_when_no_monsters_are_alive() -> void:
	_hire_hireling()
	hireling.setup(dungeon_level, Vector2i(5, 2))

	assert_true(hireling.take_turn())
	assert_eq(hireling.get_current_cell(), Vector2i(4, 2))


func test_hired_hireling_routes_around_a_corner_to_follow_the_player() -> void:
	_hire_hireling()
	hireling.setup(dungeon_level, Vector2i(3, 5))
	_place_entity(player, Vector2i(5, 5))
	dungeon_level.tiles[5][4] = DungeonLevel.WALL

	assert_true(hireling.take_turn())
	assert_eq(hireling.get_current_cell(), Vector2i(3, 4))


func test_player_can_pass_through_hired_hireling_in_a_doorway() -> void:
	_hire_hireling()
	hireling.setup(dungeon_level, Vector2i(3, 2))

	assert_true(player.try_move(Vector2i(1, 0)))
	assert_eq(player.get_current_cell(), Vector2i(3, 2))
	assert_eq(hireling.get_current_cell(), Vector2i(2, 2))

	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout

	assert_false(player.is_moving)


func test_hired_hireling_follows_automatically_after_the_player_moves() -> void:
	_hire_hireling()
	hireling.setup(dungeon_level, Vector2i(5, 2))

	assert_true(player.try_move(Vector2i(0, 1)))
	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.35).timeout

	assert_eq(hireling.get_current_cell(), Vector2i(4, 2))


func test_player_death_transfers_control_to_a_hired_hireling() -> void:
	_hire_hireling()

	assert_eq(player.take_damage(DungeonPlayer.MAX_HEARTS), DungeonPlayer.MAX_HEARTS)

	assert_false(dungeon_level.is_game_over)
	assert_eq(dungeon_level.get_player(), hireling)
	assert_true(hireling.is_controlled)
	assert_false(player.is_player_entity())


func test_input_controls_the_hireling_after_player_death() -> void:
	_hire_hireling()
	player.take_damage(DungeonPlayer.MAX_HEARTS)

	var move_event: InputEventKey = InputEventKey.new()
	move_event.keycode = KEY_RIGHT
	move_event.pressed = true
	player._unhandled_input(move_event)

	assert_eq(hireling.get_current_cell(), Vector2i(4, 2))


func test_input_heals_the_controlled_hireling() -> void:
	_hire_hireling()
	player.take_damage(DungeonPlayer.MAX_HEARTS)
	hireling.take_damage(5)
	player.inventory.add_item("Crimson Draught")

	var heal_event: InputEventKey = InputEventKey.new()
	heal_event.keycode = KEY_R
	heal_event.pressed = true
	player._unhandled_input(heal_event)

	assert_eq(hireling.health.current_hearts, 13)
	assert_eq(player.health.current_hearts, 0)
	assert_eq(player.inventory.get_item_count("Crimson Draught"), 0)


func test_controlled_hireling_picks_up_items_into_the_player_inventory() -> void:
	_hire_hireling()
	player.take_damage(DungeonPlayer.MAX_HEARTS)
	dungeon_level.spawn_pickup("Amber Potion", Vector2i(4, 2))

	assert_true(hireling.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout

	assert_eq(player.inventory.get_item_count("Amber Potion"), 1)
	assert_eq(dungeon_level.pickups.size(), 0)


func test_controlled_hireling_can_destroy_the_monster_spawner() -> void:
	_hire_hireling()
	player.take_damage(DungeonPlayer.MAX_HEARTS)
	var spawner: MonsterSpawner = dungeon_level.get_monster_spawner()
	spawner.current_cell = Vector2i(4, 2)
	spawner.position = dungeon_level.cell_to_world(spawner.current_cell)
	spawner.health.current_hearts = DungeonHireling.ATTACK_DAMAGE
	var spawner_health: HeartHealth = spawner.health

	assert_true(hireling.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(DungeonEntity.ATTACK_LUNGE_DURATION + HitEffect.DURATION + 0.05).timeout

	assert_true(spawner_health.is_depleted())


func test_dead_hireling_causes_game_over_when_player_dies() -> void:
	_hire_hireling()

	assert_eq(hireling.take_damage(DungeonHireling.MAX_HEARTS), DungeonHireling.MAX_HEARTS)
	assert_true(dungeon_level.is_hireling_dead)
	assert_false(dungeon_level.is_game_over)

	player.take_damage(DungeonPlayer.MAX_HEARTS)

	assert_true(dungeon_level.is_game_over)
	assert_null(dungeon_level.get_player())


func _hire_hireling() -> void:
	for _coin_index: int in range(DungeonLevel.HIRELING_COST):
		player.inventory.add_item("Ancient Coin")
	assert_true(dungeon_level.interact_with_hireling(player.current_cell, player.inventory))


func _set_up_test_map() -> void:
	dungeon_level.tiles.clear()
	for _y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for _x: int in range(DungeonLevel.GRID_WIDTH):
			row.append(DungeonLevel.FLOOR)
		dungeon_level.tiles.append(row)


func _place_entity(entity: DungeonEntity, cell: Vector2i) -> void:
	entity.current_cell = cell
	entity.position = dungeon_level.cell_to_world(cell)
