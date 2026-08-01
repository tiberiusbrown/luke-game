class_name PlayerInventory
extends RefCounted

signal inventory_changed
signal weapon_equipped(weapon: WeaponData)
signal weapon_wielded(weapon: WeaponData)
signal weapon_unwielded(weapon: WeaponData)

var _items: Array[String] = []
var _weapons: Array[WeaponData] = []
var equipped_weapon: WeaponData = null


func add_item(item_name: String) -> void:
	var normalized_name: String = item_name.strip_edges()
	if normalized_name.is_empty():
		return

	_items.append(normalized_name)
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
