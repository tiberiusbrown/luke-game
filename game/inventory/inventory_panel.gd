class_name InventoryPanel
extends Panel

@onready var item_list_label: Label = %ItemListLabel
@onready var total_label: Label = %TotalLabel


func refresh(inventory: PlayerInventory) -> void:
	var item_counts: Dictionary = inventory.get_item_counts()
	var item_names: Array[String] = []
	for item_name: String in item_counts.keys():
		item_names.append(item_name)
	item_names.sort()

	if item_names.is_empty():
		item_list_label.text = "YOUR PACK IS EMPTY\n\nExplore the dungeon to find items."
	else:
		var item_lines: PackedStringArray = PackedStringArray()
		for item_name: String in item_names:
			var item_count: int = int(item_counts[item_name])
			var weapons: Array[WeaponData] = inventory.get_weapons_named(item_name)
			var healing_item: HealingItemData = inventory.get_healing_item(item_name)
			if not weapons.is_empty():
				for weapon: WeaponData in weapons:
					item_lines.append(
						"%s   %d HEARTS/HIT   %d HITS LEFT" % [
							weapon.weapon_name.to_upper(),
							weapon.attack_damage,
							weapon.hits_remaining,
						]
					)
				continue

			var detail_text: String = ""
			if healing_item != null:
				detail_text = "   +%d HEARTS" % healing_item.healing_hearts
			item_lines.append("%s   x%d%s" % [item_name.to_upper(), item_count, detail_text])
		item_list_label.text = "\n".join(item_lines)

	total_label.text = "%d ITEM%s" % [
		inventory.get_total_item_count(),
		"" if inventory.get_total_item_count() == 1 else "S",
	]
