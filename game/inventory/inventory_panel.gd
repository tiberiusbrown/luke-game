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
			var weapon_damage: int = inventory.get_weapon_attack_damage(item_name)
			var damage_text: String = "   %d HEARTS/HIT" % weapon_damage if weapon_damage > 0 else ""
			item_lines.append("%s   x%d%s" % [item_name.to_upper(), item_count, damage_text])
		item_list_label.text = "\n".join(item_lines)

	total_label.text = "%d ITEM%s" % [
		inventory.get_total_item_count(),
		"" if inventory.get_total_item_count() == 1 else "S",
	]
