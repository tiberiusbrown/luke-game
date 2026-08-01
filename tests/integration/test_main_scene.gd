extends GutTest

var main_scene: Node2D


func before_each() -> void:
	var packed_scene: PackedScene = load("res://game/main/main.tscn")
	main_scene = packed_scene.instantiate() as Node2D
	add_child_autofree(main_scene)
	await get_tree().process_frame


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
	assert_eq(vendor.inventory.get_total_item_count(), 3)


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

	assert_eq(dungeon_level.enemies.size(), 12)
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
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var original_viewport_size: Vector2 = viewport.size
	var resized_viewport_size: Vector2 = Vector2(1280.0, 720.0)

	viewport.size = resized_viewport_size
	await get_tree().process_frame

	var actual_viewport_size: Vector2 = main_scene.get_viewport_rect().size
	assert_ne(actual_viewport_size, original_viewport_size)
	assert_eq(status_log.position.x + status_log.size.x, actual_viewport_size.x - 16.0)
	var map_size: Vector2 = Vector2(
		DungeonLevel.GRID_WIDTH * DungeonLevel.TILE_SIZE,
		DungeonLevel.GRID_HEIGHT * DungeonLevel.TILE_SIZE,
	)
	assert_lt(dungeon_level.position.x + dungeon_level.scale.x * map_size.x, status_log.position.x)
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
