class_name PlayerInventory
extends RefCounted

signal inventory_changed
signal weapon_equipped(weapon: WeaponData)
signal weapon_wielded(weapon: WeaponData)
signal weapon_unwielded(weapon: WeaponData)

var _items: Array[String] = []
var _regular_items: Array[String] = []
var _healing_items: Array[HealingItemData] = []
var _weapons: Array[WeaponData] = []
var equipped_weapon: WeaponData = null


func add_item(item_name: String) -> void:
	var normalized_name: String = item_name.strip_edges()
	if normalized_name.is_empty():
		return

	var healing_item: HealingItemData = HealingItemData.from_name(normalized_name)
	if healing_item != null:
		add_healing_item(healing_item)
		return

	_items.append(normalized_name)
	_regular_items.append(normalized_name)
	inventory_changed.emit()


func add_healing_item(healing_item: HealingItemData) -> void:
	if healing_item == null or healing_item.item_name.is_empty():
		return

	_healing_items.append(healing_item)
	_items.append(healing_item.item_name)
	_regular_items.append(healing_item.item_name)
	inventory_changed.emit()


func add_weapon(weapon: WeaponData) -> void:
	if weapon == null:
		return

	_weapons.append(weapon)
	_items.append(weapon.weapon_name)
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


func get_weapons() -> Array[WeaponData]:
	var weapons: Array[WeaponData] = []
	for weapon: WeaponData in _weapons:
		weapons.append(weapon)
	return weapons


func get_healing_items() -> Array[HealingItemData]:
	var healing_items: Array[HealingItemData] = []
	for healing_item: HealingItemData in _healing_items:
		healing_items.append(healing_item)
	return healing_items


func get_healing_item(item_name: String) -> HealingItemData:
	for healing_item: HealingItemData in _healing_items:
		if healing_item.item_name == item_name:
			return healing_item
	return null


func get_trade_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for item_name: String in _regular_items:
		entries.append(_make_trade_entry(item_name))
	for weapon: WeaponData in _weapons:
		entries.append(_make_trade_entry(weapon.weapon_name, weapon))
	return entries


func has_trade_entry(entry: Dictionary) -> bool:
	var weapon: WeaponData = _get_weapon_from_entry(entry)
	if weapon != null:
		return _contains_weapon(weapon)

	var item_name: String = _get_item_name_from_entry(entry)
	return _regular_items.has(item_name)


func remove_trade_entry(entry: Dictionary) -> bool:
	var weapon: WeaponData = _get_weapon_from_entry(entry)
	if weapon != null:
		return remove_weapon(weapon)
	return remove_item(_get_item_name_from_entry(entry))


func add_trade_entry(entry: Dictionary) -> void:
	var weapon: WeaponData = _get_weapon_from_entry(entry)
	if weapon != null:
		add_weapon(weapon)
		return
	add_item(_get_item_name_from_entry(entry))


func get_wieldable_weapons() -> Array[WeaponData]:
	return get_weapons()


func get_equipped_weapon() -> WeaponData:
	return equipped_weapon


func is_weapon_wielded(weapon: WeaponData) -> bool:
	return weapon != null and equipped_weapon == weapon


func wield_weapon(weapon: WeaponData) -> bool:
	if weapon == null or not _contains_weapon(weapon):
		return false
	if equipped_weapon == weapon:
		return true

	var previous_weapon: WeaponData = equipped_weapon
	equipped_weapon = weapon
	inventory_changed.emit()
	if previous_weapon != null:
		weapon_unwielded.emit(previous_weapon)
	weapon_equipped.emit(weapon)
	weapon_wielded.emit(weapon)
	return true


func unwield_weapon(weapon: WeaponData) -> bool:
	if weapon == null or equipped_weapon != weapon:
		return false

	equipped_weapon = null
	inventory_changed.emit()
	weapon_unwielded.emit(weapon)
	return true


func remove_item(item_name: String) -> bool:
	var normalized_name: String = item_name.strip_edges()
	var item_index: int = _regular_items.find(normalized_name)
	if item_index < 0:
		return false

	_regular_items.remove_at(item_index)
	_remove_first_item_name(normalized_name)
	_remove_first_healing_item_named(normalized_name)
	inventory_changed.emit()
	return true


func remove_healing_item(healing_item: HealingItemData) -> bool:
	if healing_item == null:
		return false

	var healing_item_index: int = _healing_items.find(healing_item)
	if healing_item_index < 0:
		return false

	_healing_items.remove_at(healing_item_index)
	var regular_item_index: int = _regular_items.find(healing_item.item_name)
	if regular_item_index >= 0:
		_regular_items.remove_at(regular_item_index)
	_remove_first_item_name(healing_item.item_name)
	inventory_changed.emit()
	return true


func remove_weapon(weapon: WeaponData) -> bool:
	if weapon == null:
		return false

	var weapon_index: int = _weapons.find(weapon)
	if weapon_index < 0:
		return false

	var was_equipped: bool = equipped_weapon == weapon
	_weapons.remove_at(weapon_index)
	_remove_first_item_name(weapon.weapon_name)
	if was_equipped:
		equipped_weapon = null
	inventory_changed.emit()
	if was_equipped:
		weapon_unwielded.emit(weapon)
	return true


func toggle_weapon_wielded(weapon: WeaponData) -> bool:
	if is_weapon_wielded(weapon):
		return unwield_weapon(weapon)
	return wield_weapon(weapon)


func get_weapon_attack_damage(weapon_name: String) -> int:
	for weapon: WeaponData in _weapons:
		if weapon.weapon_name == weapon_name:
			return weapon.attack_damage
	return 0


func get_total_item_count() -> int:
	return _items.size()


func is_empty() -> bool:
	return _items.is_empty()


func _contains_weapon(weapon: WeaponData) -> bool:
	for stored_weapon: WeaponData in _weapons:
		if stored_weapon == weapon:
			return true
	return false


func _make_trade_entry(item_name: String, weapon: WeaponData = null) -> Dictionary:
	return {
		"item_name": item_name,
		"weapon": weapon,
	}


func _get_item_name_from_entry(entry: Dictionary) -> String:
	return str(entry.get("item_name", "")).strip_edges()


func _get_weapon_from_entry(entry: Dictionary) -> WeaponData:
	var weapon_value: Variant = entry.get("weapon", null)
	if weapon_value is WeaponData:
		return weapon_value as WeaponData
	return null


func _remove_first_item_name(item_name: String) -> void:
	var item_index: int = _items.find(item_name)
	if item_index >= 0:
		_items.remove_at(item_index)


func _remove_first_healing_item_named(item_name: String) -> void:
	for index: int in range(_healing_items.size()):
		if _healing_items[index].item_name == item_name:
			_healing_items.remove_at(index)
			return
