extends GutTest

var main_scene: Node2D


func before_each() -> void:
	var packed_scene: PackedScene = load("res://game/main/main.tscn")
	main_scene = packed_scene.instantiate() as Node2D
	add_child_autofree(main_scene)
	await get_tree().process_frame
	var begin_event: InputEventKey = InputEventKey.new()
	begin_event.keycode = KEY_ENTER
	begin_event.pressed = true
	main_scene._input(begin_event)
	await get_tree().process_frame


func test_main_scene_shows_and_dismisses_the_tutorial() -> void:
	var packed_scene: PackedScene = load("res://game/main/main.tscn")
	var fresh_scene: Node2D = packed_scene.instantiate() as Node2D
	add_child_autofree(fresh_scene)
	await get_tree().process_frame

	var tutorial_overlay: Control = fresh_scene.get_node("%TutorialOverlay") as Control
	assert_true(tutorial_overlay.visible)

	var begin_event: InputEventKey = InputEventKey.new()
	begin_event.keycode = KEY_ENTER
	begin_event.pressed = true
	fresh_scene._input(begin_event)

	assert_false(tutorial_overlay.visible)


func test_tutorial_applies_easy_difficulty_without_a_boss_or_spawner() -> void:
	var packed_scene: PackedScene = load("res://game/main/main.tscn")
	var easy_scene: Node2D = packed_scene.instantiate() as Node2D
	add_child_autofree(easy_scene)
	await get_tree().process_frame

	var difficulty_button: OptionButton = easy_scene.get_node(
		"%DifficultyOptionButton"
	) as OptionButton
	difficulty_button.select(DungeonLevel.Difficulty.EASY)
	easy_scene._on_difficulty_selected(DungeonLevel.Difficulty.EASY)
	easy_scene._on_begin_button_pressed()
	await get_tree().process_frame

	var dungeon_level: DungeonLevel = easy_scene.get_node("%DungeonLevel") as DungeonLevel
	assert_eq(dungeon_level.get_difficulty(), DungeonLevel.Difficulty.EASY)
	assert_false(dungeon_level.has_boss())
	assert_null(dungeon_level.get_monster_spawner())
	var zombie: DungeonEnemy = _find_enemy_of_type(dungeon_level, ZombieEnemy)
	assert_not_null(zombie)
	if zombie != null:
		assert_eq(zombie.get_attack_damage(), ZombieEnemy.ATTACK_DAMAGE - 1)


func test_tutorial_applies_hard_difficulty_with_a_spawner_and_default_damage() -> void:
	var packed_scene: PackedScene = load("res://game/main/main.tscn")
	var hard_scene: Node2D = packed_scene.instantiate() as Node2D
	add_child_autofree(hard_scene)
	await get_tree().process_frame

	var difficulty_button: OptionButton = hard_scene.get_node(
		"%DifficultyOptionButton"
	) as OptionButton
	difficulty_button.select(DungeonLevel.Difficulty.HARD)
	hard_scene._on_difficulty_selected(DungeonLevel.Difficulty.HARD)
	hard_scene._on_begin_button_pressed()
	await get_tree().process_frame

	var dungeon_level: DungeonLevel = hard_scene.get_node("%DungeonLevel") as DungeonLevel
	assert_eq(dungeon_level.get_difficulty(), DungeonLevel.Difficulty.HARD)
	assert_true(dungeon_level.has_boss())
	assert_not_null(dungeon_level.get_monster_spawner())
	var zombie: DungeonEnemy = _find_enemy_of_type(dungeon_level, ZombieEnemy)
	assert_not_null(zombie)
	if zombie != null:
		assert_eq(zombie.get_attack_damage(), ZombieEnemy.ATTACK_DAMAGE)


func test_main_scene_displays_position_hud() -> void:
	var position_label: Label = main_scene.get_node("%PositionLabel") as Label

	assert_not_null(position_label)
	assert_true(position_label.text.begins_with("POSITION  "))


func test_main_scene_contains_generated_dungeon() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel

	assert_not_null(dungeon_level)
	assert_true(dungeon_level.is_walkable(dungeon_level.get_start_cell()))
	assert_gt(dungeon_level.pickups.size(), 0)


func test_main_scene_contains_a_locked_boss_prison_and_its_key() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var prison_room: Rect2i = dungeon_level.get_prison_room()
	var key_count: int = 0
	for pickup: ItemPickup in dungeon_level.pickups:
		if pickup.item_name == DungeonLevel.BOSS_PRISON_KEY:
			key_count += 1

	assert_ne(prison_room.size, Vector2i.ZERO)
	assert_true(prison_room.has_point(dungeon_level.get_prison_boss_cell()))
	assert_true(dungeon_level.is_boss_prison_locked())
	assert_false(dungeon_level.is_walkable(dungeon_level.get_prison_door_cell()))
	assert_null(dungeon_level.get_prison_boss())
	assert_eq(key_count, 1)


func test_boss_prison_unlock_consumes_the_key_and_spawns_the_cyclopes() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var approach_cell: Vector2i = _get_adjacent_empty_cell(
		dungeon_level,
		dungeon_level.get_prison_door_cell(),
	)
	player.current_cell = approach_cell
	player.position = dungeon_level.cell_to_world(approach_cell)
	player.inventory.add_item(DungeonLevel.BOSS_PRISON_KEY)

	assert_true(dungeon_level.interact_with_prison(player.current_cell, player.inventory))

	var boss: CyclopesEnemy = dungeon_level.get_prison_boss()
	assert_true(dungeon_level.is_boss_prison_unlocked())
	assert_true(dungeon_level.is_walkable(dungeon_level.get_prison_door_cell()))
	assert_eq(player.inventory.get_item_count(DungeonLevel.BOSS_PRISON_KEY), 0)
	assert_not_null(boss)
	assert_eq(boss.health.max_hearts, 30)
	assert_true(dungeon_level.enemies.has(boss))


func test_boss_prison_stays_locked_without_its_key() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var approach_cell: Vector2i = _get_adjacent_empty_cell(
		dungeon_level,
		dungeon_level.get_prison_door_cell(),
	)
	player.current_cell = approach_cell
	player.position = dungeon_level.cell_to_world(approach_cell)

	assert_true(dungeon_level.interact_with_prison(player.current_cell, player.inventory))
	assert_true(dungeon_level.is_boss_prison_locked())
	assert_null(dungeon_level.get_prison_boss())
	assert_false(dungeon_level.is_walkable(dungeon_level.get_prison_door_cell()))
	var status_log: StatusLog = main_scene.get_node("%StatusLog") as StatusLog
	assert_true(status_log.get_messages().has("The Boss Prison is locked. Find a Boss Prison Key."))


func test_unlocked_cyclopes_attacks_after_the_player_moves_into_range() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	dungeon_level._clear_enemies()
	_set_all_floor(dungeon_level)

	player.current_cell = Vector2i(1, 2)
	player.position = dungeon_level.cell_to_world(player.current_cell)
	player.inventory.add_item(DungeonLevel.BOSS_PRISON_KEY)
	var door_approach_cell: Vector2i = _get_adjacent_empty_cell(
		dungeon_level,
		dungeon_level.get_prison_door_cell(),
	)
	player.current_cell = door_approach_cell
	player.position = dungeon_level.cell_to_world(door_approach_cell)
	assert_true(dungeon_level.interact_with_prison(player.current_cell, player.inventory))

	var boss: CyclopesEnemy = dungeon_level.get_prison_boss()
	assert_not_null(boss)
	boss.hit_chance = 1.0
	player.current_cell = Vector2i(1, 2)
	player.position = dungeon_level.cell_to_world(player.current_cell)
	boss.current_cell = Vector2i(3, 2)
	boss.position = dungeon_level.cell_to_world(boss.current_cell)
	dungeon_level.refresh_visibility()
	dungeon_level.turn_scheduler.remove_entity(boss)
	assert_false(dungeon_level.turn_scheduler.has_entity(boss))

	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(0.8).timeout

	assert_eq(player.health.current_hearts, DungeonPlayer.MAX_HEARTS - CyclopesEnemy.ATTACK_DAMAGE)


func test_cyclopes_can_cross_the_generated_prison_door_and_attack() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	dungeon_level._clear_enemies()

	var outside_cell: Vector2i = _get_prison_outside_cell(dungeon_level)
	player.current_cell = outside_cell
	player.position = dungeon_level.cell_to_world(outside_cell)
	player.inventory.add_item(DungeonLevel.BOSS_PRISON_KEY)
	assert_true(dungeon_level.interact_with_prison(player.current_cell, player.inventory))

	var boss: CyclopesEnemy = dungeon_level.get_prison_boss()
	assert_not_null(boss)
	boss.hit_chance = 1.0
	var starting_hearts: int = player.health.current_hearts
	for _turn: int in range(12):
		if player.health.current_hearts < starting_hearts:
			break
		assert_true(boss.take_turn())
		await get_tree().create_timer(0.4).timeout

	assert_eq(player.health.current_hearts, starting_hearts - CyclopesEnemy.ATTACK_DAMAGE)


func test_cyclopes_attacks_during_real_player_turns_in_the_generated_prison() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	dungeon_level._clear_enemies()

	var outside_cell: Vector2i = _get_prison_outside_cell(dungeon_level)
	var door_cell: Vector2i = dungeon_level.get_prison_door_cell()
	var direction_to_door: Vector2i = door_cell - outside_cell
	player.current_cell = outside_cell
	player.position = dungeon_level.cell_to_world(outside_cell)
	player.inventory.add_item(DungeonLevel.BOSS_PRISON_KEY)
	assert_true(dungeon_level.interact_with_prison(player.current_cell, player.inventory))

	var boss: CyclopesEnemy = dungeon_level.get_prison_boss()
	assert_not_null(boss)
	boss.hit_chance = 1.0
	var starting_hearts: int = player.health.current_hearts
	for _turn: int in range(12):
		var player_direction: Vector2i = direction_to_door if player.current_cell == outside_cell else -direction_to_door
		assert_true(player.try_move(player_direction))
		await get_tree().create_timer(0.6).timeout
		if player.health.current_hearts < starting_hearts:
			break

	assert_eq(player.health.current_hearts, starting_hearts - CyclopesEnemy.ATTACK_DAMAGE)


func test_cyclopes_attacks_while_the_player_waits_in_range() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	dungeon_level._clear_enemies()
	_set_all_floor(dungeon_level)

	player.current_cell = Vector2i(2, 2)
	player.position = dungeon_level.cell_to_world(player.current_cell)
	player.inventory.add_item(DungeonLevel.BOSS_PRISON_KEY)
	var door_approach_cell: Vector2i = _get_adjacent_empty_cell(
		dungeon_level,
		dungeon_level.get_prison_door_cell(),
	)
	player.current_cell = door_approach_cell
	player.position = dungeon_level.cell_to_world(door_approach_cell)
	assert_true(dungeon_level.interact_with_prison(player.current_cell, player.inventory))

	var boss: CyclopesEnemy = dungeon_level.get_prison_boss()
	assert_not_null(boss)
	boss.hit_chance = 1.0
	boss.current_cell = Vector2i(3, 2)
	boss.position = dungeon_level.cell_to_world(boss.current_cell)
	player.current_cell = Vector2i(2, 2)
	player.position = dungeon_level.cell_to_world(player.current_cell)
	dungeon_level.turn_scheduler.remove_entity(boss)
	dungeon_level.refresh_visibility()

	await get_tree().create_timer(CyclopesEnemy.ATTACK_COOLDOWN * 0.75).timeout

	assert_eq(player.health.current_hearts, DungeonPlayer.MAX_HEARTS - CyclopesEnemy.ATTACK_DAMAGE)


func _get_prison_outside_cell(dungeon_level: DungeonLevel) -> Vector2i:
	var door_cell: Vector2i = dungeon_level.get_prison_door_cell()
	var directions: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for direction: Vector2i in directions:
		var candidate_cell: Vector2i = door_cell + direction
		if not dungeon_level.get_prison_room().has_point(candidate_cell) and dungeon_level.is_walkable(candidate_cell):
			return candidate_cell
	return door_cell


func _find_enemy_of_type(dungeon_level: DungeonLevel, enemy_type: Script) -> DungeonEnemy:
	for enemy: DungeonEnemy in dungeon_level.enemies:
		if enemy.get_script() == enemy_type:
			return enemy
	return null


func _set_all_floor(dungeon_level: DungeonLevel) -> void:
	dungeon_level.tiles.clear()
	for _y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for _x: int in range(DungeonLevel.GRID_WIDTH):
			row.append(DungeonLevel.FLOOR)
		dungeon_level.tiles.append(row)


func test_main_scene_contains_weapon_pickups() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var has_weapon_pickup: bool = false
	for pickup: ItemPickup in dungeon_level.pickups:
		if pickup.weapon_data != null:
			has_weapon_pickup = true
			break

	assert_true(has_weapon_pickup)


func test_main_scene_contains_a_dedicated_vendor_room() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var vendor: DungeonVendor = dungeon_level.get_vendor()

	assert_not_null(vendor)
	assert_true(dungeon_level.get_vendor_room().has_point(vendor.cell))
	assert_ne(vendor.cell, dungeon_level.get_start_cell())
	assert_ne(vendor.cell, dungeon_level.get_exit_cell())
	assert_eq(vendor.inventory.get_total_item_count(), 10)


func test_vendor_opens_when_player_presses_e_while_adjacent() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var vendor_panel: VendorPanel = main_scene.get_node("%VendorPanel") as VendorPanel
	var vendor: DungeonVendor = dungeon_level.get_vendor()
	var adjacent_cell: Vector2i = _get_adjacent_walkable_cell(dungeon_level, vendor.cell)
	player.current_cell = adjacent_cell
	player.position = dungeon_level.cell_to_world(adjacent_cell)
	player.inventory.add_item("Ancient Coin")
	var interact_event: InputEventKey = InputEventKey.new()
	interact_event.keycode = KEY_E
	interact_event.pressed = true

	player._unhandled_input(interact_event)

	assert_true(vendor_panel.visible)
	assert_eq(player.get_current_cell(), adjacent_cell)

	var exchange_event: InputEventKey = InputEventKey.new()
	exchange_event.keycode = KEY_ENTER
	exchange_event.pressed = true
	main_scene._input(exchange_event)

	assert_eq(player.inventory.get_item_count("Ancient Coin"), 0)
	assert_eq(player.inventory.get_item_count("Amber Potion"), 1)
	var status_log: StatusLog = main_scene.get_node("%StatusLog") as StatusLog
	assert_true(status_log.get_messages().has("Rook trades Ancient Coin for Amber Potion"))


func test_player_presses_e_to_hire_an_adjacent_fighter() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var hireling: DungeonHireling = dungeon_level.get_hireling()
	var adjacent_cell: Vector2i = _get_adjacent_empty_cell(dungeon_level, hireling.current_cell)
	player.current_cell = adjacent_cell
	player.position = dungeon_level.cell_to_world(adjacent_cell)
	for _coin_index: int in range(DungeonLevel.HIRELING_COST):
		player.inventory.add_item("Ancient Coin")

	var interact_event: InputEventKey = InputEventKey.new()
	interact_event.keycode = KEY_E
	interact_event.pressed = true
	player._unhandled_input(interact_event)

	assert_true(dungeon_level.is_hireling_hired())
	assert_true(hireling.is_hired)
	assert_eq(player.inventory.get_item_count("Ancient Coin"), 0)
	var status_log: StatusLog = main_scene.get_node("%StatusLog") as StatusLog
	assert_true(status_log.get_messages().has("You hire the fighter for 5 Ancient Coins"))


func test_hireling_notification_pops_up_when_player_is_near_the_fighter() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var hireling: DungeonHireling = dungeon_level.get_hireling()
	var prompt_panel: Panel = main_scene.get_node("%HirelingPromptPanel") as Panel
	var prompt_label: Label = main_scene.get_node("%PromptLabel") as Label
	var adjacent_cell: Vector2i = _get_adjacent_empty_cell(dungeon_level, hireling.current_cell)
	player.current_cell = adjacent_cell
	player.position = dungeon_level.cell_to_world(adjacent_cell)

	await get_tree().process_frame

	assert_true(prompt_panel.visible)
	assert_true(prompt_label.text.contains("PRESS E TO HIRE FIGHTER"))
	assert_true(prompt_label.text.contains("5 ANCIENT COINS"))


func test_vendor_panel_keeps_the_offer_prompt_below_a_full_player_inventory() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var vendor_panel: VendorPanel = main_scene.get_node("%VendorPanel") as VendorPanel
	var vendor: DungeonVendor = dungeon_level.get_vendor()
	for item_name: String in DungeonLevel.ITEM_NAMES:
		player.inventory.add_item(item_name)
	for weapon_definition: Dictionary in DungeonLevel.WEAPON_DEFINITIONS:
		player.inventory.add_weapon(
			WeaponData.new(
				str(weapon_definition["name"]),
				int(weapon_definition["damage"]),
			)
		)
	for _coin_index: int in range(20):
		player.inventory.add_item("Ancient Coin")

	vendor_panel.show_vendor(vendor, player.inventory)
	await get_tree().process_frame

	var player_offer_label: Label = main_scene.get_node("%PlayerOfferLabel") as Label
	var selected_side_label: Label = main_scene.get_node("%SelectedSideLabel") as Label
	var trade_status_label: Label = main_scene.get_node("%TradeStatusLabel") as Label
	var offer_bottom: float = player_offer_label.position.y + player_offer_label.get_combined_minimum_size().y
	var status_bottom: float = trade_status_label.position.y + trade_status_label.get_combined_minimum_size().y

	assert_lte(offer_bottom, selected_side_label.position.y)
	assert_lte(status_bottom, vendor_panel.size.y)


func test_main_scene_spawns_all_enemy_types_without_health_ui() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var enemy_types: Array[String] = []
	for enemy: DungeonEnemy in dungeon_level.enemies:
		enemy_types.append(enemy.enemy_type)

	assert_eq(dungeon_level.enemies.size(), 16)
	var skeleton_count: int = 0
	for enemy: DungeonEnemy in dungeon_level.enemies:
		if enemy is SkeletonEnemy:
			skeleton_count += 1
	assert_eq(skeleton_count, 5)
	assert_true(enemy_types.has("Zombie"))
	assert_true(enemy_types.has("Skeleton"))
	assert_true(enemy_types.has("Vampire"))
	assert_true(enemy_types.has("Spider"))
	assert_true(enemy_types.has("Ghost"))
	assert_true(enemy_types.has("Goblin"))
	assert_true(enemy_types.has("Orc"))
	assert_true(enemy_types.has("Slime"))
	assert_true(enemy_types.has("Mummy"))
	assert_true(enemy_types.has("Wraith"))
	assert_true(enemy_types.has("Golem"))
	assert_true(enemy_types.has("Lich"))
	assert_eq(main_scene.get_node("%HealthBar").get_parent().name, "Hud")


func test_player_starts_on_an_edge_and_monsters_spawn_on_the_opposite_side() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer

	assert_eq(player.get_current_cell(), dungeon_level.get_start_cell())
	assert_true(dungeon_level.is_map_edge_cell(player.get_current_cell()))
	assert_eq(dungeon_level.monster_spawn_cells.size(), dungeon_level.enemies.size())
	for enemy: DungeonEnemy in dungeon_level.enemies:
		assert_true(
			dungeon_level.is_cell_on_side(
				enemy.get_current_cell(),
				dungeon_level.get_monster_spawn_side(),
			)
		)


func test_main_scene_binds_the_ten_heart_player_health_to_the_hud() -> void:
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var health_bar: HeartHealthBar = main_scene.get_node("%HealthBar") as HeartHealthBar

	assert_eq(player.health.max_hearts, 10)
	assert_true(health_bar is HeartHealthBar)
	assert_gt(health_bar.custom_minimum_size.x, 0.0)

	player.take_damage(2)
	await get_tree().process_frame

	assert_eq(player.health.current_hearts, 8)


func test_main_scene_hands_control_to_the_hired_fighter_and_shows_game_over() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var hireling: DungeonHireling = dungeon_level.get_hireling()
	var health_bar: HeartHealthBar = main_scene.get_node("%HealthBar") as HeartHealthBar
	var game_over_panel: Panel = main_scene.get_node("%GameOverPanel") as Panel
	var adjacent_cell: Vector2i = _get_adjacent_empty_cell(dungeon_level, hireling.current_cell)
	player.current_cell = adjacent_cell
	player.position = dungeon_level.cell_to_world(adjacent_cell)
	for _coin_index: int in range(DungeonLevel.HIRELING_COST):
		player.inventory.add_item("Ancient Coin")

	assert_true(dungeon_level.interact_with_hireling(player.current_cell, player.inventory))
	assert_true(dungeon_level.is_hireling_hired())

	player.take_damage(DungeonPlayer.MAX_HEARTS)
	assert_eq(dungeon_level.get_player(), hireling)
	assert_eq(
		health_bar.custom_minimum_size.x,
		DungeonHireling.MAX_HEARTS * HeartHealthBar.HEART_WIDTH
		+ (DungeonHireling.MAX_HEARTS - 1) * HeartHealthBar.HEART_SPACING,
	)

	hireling.take_damage(DungeonHireling.MAX_HEARTS)
	assert_true(game_over_panel.visible)


func test_resizing_keeps_status_log_right_aligned_and_map_to_its_left() -> void:
	var viewport: Viewport = main_scene.get_viewport()
	var status_log: StatusLog = main_scene.get_node("%StatusLog") as StatusLog
	var map_viewport: Control = main_scene.get_node("%MapViewport") as Control
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var original_viewport_size: Vector2 = viewport.size
	var resized_viewport_size: Vector2 = Vector2(1280.0, 720.0)

	viewport.size = resized_viewport_size
	await get_tree().process_frame

	var actual_viewport_size: Vector2 = main_scene.get_viewport_rect().size
	assert_ne(actual_viewport_size, original_viewport_size)
	assert_eq(status_log.position.x + status_log.size.x, actual_viewport_size.x - 16.0)
	assert_lt(map_viewport.position.x + map_viewport.size.x, status_log.position.x)
	assert_gte(dungeon_level.scale.x, 0.55)
	assert_eq(main_scene.get_node("Background").size, actual_viewport_size)

	viewport.size = original_viewport_size


func test_i_toggles_inventory_panel() -> void:
	var inventory_panel: InventoryPanel = main_scene.get_node("%InventoryPanel") as InventoryPanel
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_I
	key_event.pressed = true

	assert_false(inventory_panel.visible)
	main_scene._unhandled_input(key_event)
	assert_true(inventory_panel.visible)
	main_scene._unhandled_input(key_event)
	assert_false(inventory_panel.visible)


func test_r_heals_the_controlled_hireling_through_main_input() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var hireling: DungeonHireling = dungeon_level.get_hireling()
	var adjacent_cell: Vector2i = _get_adjacent_empty_cell(dungeon_level, hireling.current_cell)
	player.current_cell = adjacent_cell
	player.position = dungeon_level.cell_to_world(adjacent_cell)
	for _coin_index: int in range(DungeonLevel.HIRELING_COST):
		player.inventory.add_item("Ancient Coin")

	assert_true(dungeon_level.interact_with_hireling(player.current_cell, player.inventory))
	player.take_damage(DungeonPlayer.MAX_HEARTS)
	hireling.take_damage(5)
	player.inventory.add_item("Crimson Draught")

	var heal_event: InputEventKey = InputEventKey.new()
	heal_event.keycode = KEY_R
	heal_event.pressed = true
	main_scene._input(heal_event)

	assert_eq(hireling.health.current_hearts, DungeonHireling.MAX_HEARTS)
	assert_eq(player.inventory.get_item_count("Crimson Draught"), 0)


func test_inventory_panel_scrolls_when_the_item_list_is_long() -> void:
	var inventory_panel: InventoryPanel = main_scene.get_node("%InventoryPanel") as InventoryPanel
	var item_list_scroll: ScrollContainer = main_scene.get_node(
		"%InventoryPanel/ItemListScroll"
	) as ScrollContainer
	var item_list_label: Label = main_scene.get_node("%ItemListLabel") as Label

	for item_index: int in range(16):
		main_scene.player.inventory.add_item("Unique Item %02d" % item_index)
	inventory_panel.refresh(main_scene.player.inventory)
	inventory_panel.visible = true
	await get_tree().process_frame

	assert_gt(item_list_label.size.y, item_list_scroll.size.y)
	assert_gt(item_list_scroll.get_v_scroll_bar().max_value, 0.0)
	assert_true(item_list_label.text.contains("UNIQUE ITEM 15"))


func test_w_opens_wield_panel_without_moving_the_player() -> void:
	var wield_panel: WieldPanel = main_scene.get_node("%WieldPanel") as WieldPanel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var start_cell: Vector2i = player.get_current_cell()
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_W
	key_event.pressed = true

	main_scene._input(key_event)

	assert_true(wield_panel.visible)
	assert_eq(player.get_current_cell(), start_cell)

	main_scene._input(key_event)
	assert_false(wield_panel.visible)


func test_wield_panel_moves_selection_and_toggles_the_selected_weapon() -> void:
	var wield_panel: WieldPanel = main_scene.get_node("%WieldPanel") as WieldPanel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var first_weapon: WeaponData = WeaponData.new("Bone Axe", 3)
	var second_weapon: WeaponData = WeaponData.new("Rusty Sword", 2)
	player.inventory.add_weapon(first_weapon)
	player.inventory.add_weapon(second_weapon)

	var open_event: InputEventKey = InputEventKey.new()
	open_event.keycode = KEY_W
	open_event.pressed = true
	main_scene._input(open_event)

	assert_eq(wield_panel.selected_index, 0)
	assert_eq(wield_panel.get_selected_weapon(), first_weapon)

	var down_event: InputEventKey = InputEventKey.new()
	down_event.keycode = KEY_DOWN
	down_event.pressed = true
	main_scene._input(down_event)
	assert_eq(wield_panel.selected_index, 1)

	var enter_event: InputEventKey = InputEventKey.new()
	enter_event.keycode = KEY_ENTER
	enter_event.pressed = true
	main_scene._input(enter_event)
	assert_eq(player.inventory.get_equipped_weapon(), second_weapon)

	var status_log: StatusLog = main_scene.get_node("%StatusLog") as StatusLog
	assert_true(status_log.get_messages().has("You wield the Rusty Sword"))

	main_scene._input(enter_event)
	assert_null(player.inventory.get_equipped_weapon())
	assert_true(status_log.get_messages().has("You unwield the Rusty Sword"))


func _get_adjacent_walkable_cell(dungeon_level: DungeonLevel, target_cell: Vector2i) -> Vector2i:
	var directions: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for direction: Vector2i in directions:
		var candidate_cell: Vector2i = target_cell + direction
		if dungeon_level.is_walkable(candidate_cell):
			return candidate_cell
	return target_cell


func _get_adjacent_empty_cell(dungeon_level: DungeonLevel, target_cell: Vector2i) -> Vector2i:
	var directions: Array[Vector2i] = [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]
	for direction: Vector2i in directions:
		var candidate_cell: Vector2i = target_cell + direction
		if (
			dungeon_level.is_walkable(candidate_cell)
			and dungeon_level.get_entity_at(candidate_cell) == null
			and dungeon_level.get_vendor_at(candidate_cell) == null
		):
			return candidate_cell
	return _get_adjacent_walkable_cell(dungeon_level, target_cell)


func test_h_opens_a_paused_home_screen_and_return_resumes_the_game() -> void:
	var home_panel: Panel = main_scene.get_node("%HomePanel") as Panel
	var key_event: InputEventKey = InputEventKey.new()
	key_event.keycode = KEY_H
	key_event.pressed = true

	main_scene._input(key_event)

	assert_true(home_panel.visible)
	assert_true(get_tree().paused)

	main_scene._on_return_to_game_button_pressed()

	assert_false(home_panel.visible)
	assert_false(get_tree().paused)


func test_impossible_trial_requires_five_skulls() -> void:
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var trial_button: Button = main_scene.get_node("%ImpossibleTrialButton") as Button

	assert_true(trial_button.disabled)
	main_scene._on_impossible_trial_button_pressed()
	assert_null(main_scene.trial_level)

	for _skull_index: int in range(4):
		player.inventory.add_item(DungeonLevel.SKULL_ITEM_NAME)
	assert_true(trial_button.disabled)
	player.inventory.add_item(DungeonLevel.SKULL_ITEM_NAME)
	assert_false(trial_button.disabled)


func test_impossible_trial_has_ten_cyclopes_on_a_smaller_map() -> void:
	var main_dungeon: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	for _skull_index: int in range(5):
		player.inventory.add_item(DungeonLevel.SKULL_ITEM_NAME)
	main_scene._show_home_screen()
	main_scene._on_impossible_trial_button_pressed()
	await get_tree().process_frame

	var trial: DungeonLevel = main_scene.trial_level
	assert_not_null(trial)
	if trial == null:
		return
	assert_true(trial.is_trial())
	assert_eq(trial.enemies.size(), DungeonLevel.TRIAL_CYCLOPES_COUNT)
	assert_lt(trial.get_map_size().x, main_dungeon.get_map_size().x)
	assert_lt(trial.get_map_size().y, main_dungeon.get_map_size().y)
	for enemy: DungeonEnemy in trial.enemies:
		assert_true(enemy is CyclopesEnemy)


func test_defeating_impossible_trial_returns_with_twenty_hearts_and_respawned_mobs() -> void:
	var main_dungeon: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	for _skull_index: int in range(5):
		player.inventory.add_item(DungeonLevel.SKULL_ITEM_NAME)
	main_scene._start_impossible_trial()
	await get_tree().process_frame

	var trial: DungeonLevel = main_scene.trial_level
	assert_not_null(trial)
	if trial == null:
		return
	for enemy: DungeonEnemy in trial.enemies.duplicate():
		enemy.take_damage(enemy.health.current_hearts)
	await get_tree().process_frame

	assert_null(main_scene.trial_level)
	assert_eq(player.get_parent(), main_dungeon)
	assert_eq(player.health.max_hearts, 20)
	assert_eq(player.health.current_hearts, 20)
	assert_eq(main_dungeon.enemies.size(), DungeonLevel.MONSTER_COUNT)
	assert_null(main_dungeon.get_monster_spawner())


func test_impossible_trial_uses_the_hired_fighter_after_the_player_falls() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var hireling: DungeonHireling = dungeon_level.get_hireling()
	var adjacent_cell: Vector2i = _get_adjacent_empty_cell(dungeon_level, hireling.current_cell)
	player.current_cell = adjacent_cell
	player.position = dungeon_level.cell_to_world(adjacent_cell)
	for _coin_index: int in range(DungeonLevel.HIRELING_COST):
		player.inventory.add_item("Ancient Coin")

	assert_true(dungeon_level.interact_with_hireling(player.current_cell, player.inventory))
	player.take_damage(DungeonPlayer.MAX_HEARTS)
	assert_eq(dungeon_level.get_player(), hireling)

	for _skull_index: int in range(5):
		player.inventory.add_item(DungeonLevel.SKULL_ITEM_NAME)
	main_scene._start_impossible_trial()
	await get_tree().process_frame

	var trial: DungeonLevel = main_scene.trial_level
	assert_not_null(trial)
	if trial == null:
		return
	assert_eq(trial.get_player(), hireling)
	assert_true(trial.is_cell_known(trial.get_start_cell()))
	assert_true(hireling.visible)
	assert_eq(player.get_parent(), trial)
