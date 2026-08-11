class_name WieldPanel
extends Panel

@onready var item_list_label: Label = %WieldItemListLabel
@onready var selected_label: Label = %WieldSelectedLabel

var _inventory: PlayerInventory
var _weapons: Array[WeaponData] = []
var selected_index: int = 0


func refresh(inventory: PlayerInventory) -> void:
	var previous_weapon: WeaponData = get_selected_weapon()
	_inventory = inventory
	_weapons = inventory.get_wieldable_weapons() if inventory != null else []

	if _weapons.is_empty():
		selected_index = 0
	else:
		selected_index = _find_weapon_index(previous_weapon)
		if selected_index < 0:
			selected_index = clampi(selected_index, 0, _weapons.size() - 1)

	_update_labels()


func handle_key(key_event: InputEventKey) -> bool:
	if not key_event.pressed or key_event.echo:
		return true

	if _is_key(key_event, KEY_UP):
		_move_selection(-1)
		return true
	if _is_key(key_event, KEY_DOWN):
		_move_selection(1)
		return true
	if _is_key(key_event, KEY_ENTER) or _is_key(key_event, KEY_KP_ENTER):
		_toggle_selected_weapon()
		return true
	return true


func get_selected_weapon() -> WeaponData:
	if _weapons.is_empty() or selected_index < 0 or selected_index >= _weapons.size():
		return null
	return _weapons[selected_index]


func _move_selection(offset: int) -> void:
	if _weapons.is_empty():
		return
	selected_index = posmod(selected_index + offset, _weapons.size())
	_update_labels()


func _toggle_selected_weapon() -> void:
	if _inventory == null:
		return

	var selected_weapon: WeaponData = get_selected_weapon()
	if selected_weapon == null:
		return

	_inventory.toggle_weapon_wielded(selected_weapon)
	_update_labels()


func _update_labels() -> void:
	if _weapons.is_empty():
		item_list_label.text = "NO WIELDABLE WEAPONS\n\nFind a weapon in the dungeon."
		selected_label.text = "NOTHING SELECTED"
		return

	var item_lines: PackedStringArray = PackedStringArray()
	for weapon_index: int in range(_weapons.size()):
		var weapon: WeaponData = _weapons[weapon_index]
		var marker: String = ">" if weapon_index == selected_index else " "
		var wielded_text: String = "  WIELDED" if _inventory != null and _inventory.is_weapon_wielded(weapon) else ""
		item_lines.append(
			"%s %s   %d HEARTS/HIT   %d HITS LEFT%s" % [
				marker,
				weapon.weapon_name.to_upper(),
				weapon.attack_damage,
				weapon.hits_remaining,
				wielded_text,
			]
		)
	item_list_label.text = "\n".join(item_lines)

	var selected_weapon: WeaponData = get_selected_weapon()
	if selected_weapon == null:
		selected_label.text = "NOTHING SELECTED"
	elif _inventory != null and _inventory.is_weapon_wielded(selected_weapon):
		selected_label.text = "%s IS WIELDED" % selected_weapon.weapon_name.to_upper()
	else:
		selected_label.text = "%s IS UNWIELDED" % selected_weapon.weapon_name.to_upper()


func _find_weapon_index(previous_weapon: WeaponData) -> int:
	if previous_weapon == null:
		return 0
	for weapon_index: int in range(_weapons.size()):
		if _weapons[weapon_index] == previous_weapon:
			return weapon_index
	return 0


func _is_key(key_event: InputEventKey, key_code: int) -> bool:
	return key_event.keycode == key_code or key_event.physical_keycode == key_code
