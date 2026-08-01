extends GutTest

var dungeon_level: DungeonLevel


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)


func test_cell_to_world_returns_cell_center() -> void:
	assert_eq(dungeon_level.cell_to_world(Vector2i(0, 0)), Vector2(16.0, 16.0))
	assert_eq(dungeon_level.cell_to_world(Vector2i(3, 5)), Vector2(112.0, 176.0))


func test_world_to_cell_maps_positions_to_grid_cells() -> void:
	assert_eq(dungeon_level.world_to_cell(Vector2(0.0, 0.0)), Vector2i(0, 0))
	assert_eq(dungeon_level.world_to_cell(Vector2(127.9, 64.0)), Vector2i(3, 2))


func test_generated_dungeon_spawns_each_weapon_definition_as_a_pickup() -> void:
	var weapon_names: Array[String] = []
	for pickup: ItemPickup in dungeon_level.pickups:
		if pickup.weapon_data != null:
			weapon_names.append(pickup.weapon_data.weapon_name)

	assert_eq(weapon_names.size(), DungeonLevel.WEAPON_DEFINITIONS.size())
	for weapon_definition: Dictionary in DungeonLevel.WEAPON_DEFINITIONS:
		assert_true(weapon_names.has(str(weapon_definition["name"])))


func test_generated_dungeon_spawns_many_ancient_coins() -> void:
	var coin_count: int = 0
	for pickup: ItemPickup in dungeon_level.pickups:
		if pickup.item_name == "Ancient Coin":
			coin_count += 1

	assert_gte(coin_count, DungeonLevel.ANCIENT_COIN_COUNT)
