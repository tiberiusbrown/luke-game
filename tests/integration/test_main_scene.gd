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
