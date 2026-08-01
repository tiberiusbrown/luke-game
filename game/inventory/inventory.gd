class_name PlayerInventory
extends RefCounted

signal inventory_changed

var _items: Array[String] = []


func add_item(item_name: String) -> void:
	var normalized_name: String = item_name.strip_edges()
	if normalized_name.is_empty():
		return

	_items.append(normalized_name)
	inventory_changed.emit()


func get_item_count(item_name: String) -> int:
	var count: int = 0
	for stored_item_name: String in _items:
		if stored_item_name == item_name:
			count += 1
	return count


func get_item_counts() -> Dictionary:
	var counts: Dictionary = {}
	for item_name: String in _items:
		counts[item_name] = int(counts.get(item_name, 0)) + 1
	return counts


func get_total_item_count() -> int:
	return _items.size()


func is_empty() -> bool:
	return _items.is_empty()
