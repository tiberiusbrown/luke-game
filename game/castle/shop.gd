class_name DungeonShop
extends DungeonVendor

enum ShopType { WEAPONS, HEALING }

var shop_type: ShopType = ShopType.WEAPONS
var shop_name: String = "Castle Shop"


func configure_shop(new_shop_type: ShopType) -> void:
	shop_type = new_shop_type
	inventory = PlayerInventory.new()
	if shop_type == ShopType.WEAPONS:
		shop_name = "The Castle Armory"
		inventory.add_weapon(WeaponData.new("Moonsteel Blade", 3))
		inventory.add_weapon(WeaponData.new("Iron Mace", 2))
		inventory.add_weapon(WeaponData.new("Crystal Spear", 3))
		inventory.add_weapon(WeaponData.new("Shadow Dagger", 2))
	else:
		shop_name = "The Castle Apothecary"
		for item_name: String in [
			"Amber Potion",
			"Moonleaf Tonic",
			"Sunstone",
			"Crimson Draught",
			"Heartroot Poultice",
		]:
			inventory.add_item(item_name)
	queue_redraw()


func get_display_name() -> String:
	return shop_name


func get_interaction_title() -> String:
	return shop_name.to_upper()


func get_stock_label() -> String:
	return "ARMORY STOCK" if shop_type == ShopType.WEAPONS else "APOTHECARY STOCK"


func get_trade_status() -> String:
	return "ONE ANCIENT COIN FOR ONE ITEM"
