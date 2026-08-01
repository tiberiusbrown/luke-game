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


func test_main_scene_contains_weapon_pickups() -> void:
	var dungeon_level: DungeonLevel = main_scene.get_node("%DungeonLevel") as DungeonLevel
	var has_weapon_pickup: bool = false
	for pickup: ItemPickup in dungeon_level.pickups:
		if pickup.weapon_data != null:
			has_weapon_pickup = true
			break

	assert_true(has_weapon_pickup)


func test_main_scene_binds_the_ten_heart_player_health_to_the_hud() -> void:
	var player: DungeonPlayer = main_scene.get_node("%Player") as DungeonPlayer
	var health_bar: HeartHealthBar = main_scene.get_node("%HealthBar") as HeartHealthBar

	assert_eq(player.health.max_hearts, 10)
	assert_true(health_bar is HeartHealthBar)
	assert_gt(health_bar.custom_minimum_size.x, 0.0)

	player.take_damage(2)
	await get_tree().process_frame

	assert_eq(player.health.current_hearts, 8)


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
