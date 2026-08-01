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


func test_weapon_is_stored_and_equipped_with_its_attack_damage() -> void:
	var weapon: WeaponData = WeaponData.new("Bone Axe", 3)
	inventory.add_weapon(weapon)

	assert_eq(inventory.get_total_item_count(), 1)
	assert_eq(inventory.get_item_count("Bone Axe"), 1)
	assert_eq(inventory.get_equipped_weapon(), weapon)
	assert_eq(inventory.get_weapon_attack_damage("Bone Axe"), 3)


func test_weapon_damage_is_limited_to_two_or_three_hearts() -> void:
	var weak_weapon: WeaponData = WeaponData.new("Training Blade", 1)
	var strong_weapon: WeaponData = WeaponData.new("War Hammer", 99)

	assert_eq(weak_weapon.attack_damage, 2)
	assert_eq(strong_weapon.attack_damage, 3)
