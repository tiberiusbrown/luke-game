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
