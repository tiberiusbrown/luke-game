extends GutTest

var inventory: PlayerInventory


func before_each() -> void:
	inventory = PlayerInventory.new()


func test_add_item_tracks_total_and_stacked_counts() -> void:
	inventory.add_item("Ancient Coin")
	inventory.add_item("Ancient Coin")
	inventory.add_item("Crystal Shard")

	assert_eq(inventory.get_total_item_count(), 3)
	assert_eq(inventory.get_item_count("Ancient Coin"), 2)
	assert_eq(inventory.get_item_count("Crystal Shard"), 1)


func test_blank_item_names_are_not_added() -> void:
	inventory.add_item("  ")

	assert_true(inventory.is_empty())
