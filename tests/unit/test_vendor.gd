extends GutTest

var vendor: DungeonVendor
var player_inventory: PlayerInventory


func before_each() -> void:
	vendor = DungeonVendor.new()
	add_child_autofree(vendor)
	player_inventory = PlayerInventory.new()


func test_exchange_swaps_a_regular_item_for_vendor_stock() -> void:
	player_inventory.add_item("Ancient Coin")
	var offered_entry: Dictionary = player_inventory.get_trade_entries()[0]
	var requested_entry: Dictionary = vendor.inventory.get_trade_entries()[0]

	assert_true(vendor.exchange(player_inventory, offered_entry, requested_entry))
	assert_eq(player_inventory.get_item_count("Ancient Coin"), 0)
	assert_eq(player_inventory.get_item_count("Amber Potion"), 1)
	assert_eq(vendor.inventory.get_item_count("Ancient Coin"), 1)
	assert_eq(vendor.inventory.get_item_count("Amber Potion"), 0)


func test_exchange_handles_weapons_and_unwields_an_offered_weapon() -> void:
	var offered_weapon: WeaponData = WeaponData.new("Bone Axe", 3)
	player_inventory.add_weapon(offered_weapon)
	assert_true(player_inventory.wield_weapon(offered_weapon))

	var offered_entry: Dictionary = player_inventory.get_trade_entries()[0]
	var requested_entry: Dictionary = vendor.inventory.get_trade_entries()[2]
	var requested_name: String = str(requested_entry["item_name"])

	assert_true(vendor.exchange(player_inventory, offered_entry, requested_entry))
	assert_null(player_inventory.get_equipped_weapon())
	assert_eq(player_inventory.get_item_count("Bone Axe"), 0)
	assert_eq(player_inventory.get_item_count(requested_name), 1)
	assert_eq(vendor.inventory.get_item_count("Bone Axe"), 1)


func test_invalid_exchange_does_not_remove_player_item() -> void:
	player_inventory.add_item("Ancient Coin")
	var offered_entry: Dictionary = player_inventory.get_trade_entries()[0]
	var missing_entry: Dictionary = {
		"item_name": "Missing Relic",
		"weapon": null,
	}

	assert_false(vendor.exchange(player_inventory, offered_entry, missing_entry))
	assert_eq(player_inventory.get_item_count("Ancient Coin"), 1)
