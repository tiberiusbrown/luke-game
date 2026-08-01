class_name VendorPanel
extends Panel

signal trade_completed(offered_name: String, received_name: String)
signal close_requested

@onready var player_offer_label: Label = %PlayerOfferLabel
@onready var vendor_stock_label: Label = %VendorStockLabel
@onready var selected_side_label: Label = %SelectedSideLabel
@onready var trade_status_label: Label = %TradeStatusLabel

var _vendor: DungeonVendor = null
var _player_inventory: PlayerInventory = null
var _player_entries: Array[Dictionary] = []
var _vendor_entries: Array[Dictionary] = []
var _selected_side: int = 0
var _player_selected_index: int = 0
var _vendor_selected_index: int = 0
var _status_message: String = "ONE ITEM FOR ONE ITEM"


func show_vendor(vendor: DungeonVendor, player_inventory: PlayerInventory) -> void:
	_vendor = vendor
	_player_inventory = player_inventory
	_selected_side = 0
	_status_message = "ONE ITEM FOR ONE ITEM"
	visible = true
	refresh()


func refresh() -> void:
	_player_entries = _player_inventory.get_trade_entries() if _player_inventory != null else []
	_vendor_entries = _vendor.inventory.get_trade_entries() if _vendor != null else []
	_player_selected_index = _clamp_index(_player_selected_index, _player_entries.size())
	_vendor_selected_index = _clamp_index(_vendor_selected_index, _vendor_entries.size())
	_update_labels()


func handle_key(key_event: InputEventKey) -> bool:
	if not key_event.pressed or key_event.echo:
		return true

	if _is_key(key_event, KEY_ESCAPE):
		visible = false
		close_requested.emit()
		return true
	if _is_key(key_event, KEY_LEFT) or _is_key(key_event, KEY_RIGHT):
		_selected_side = 1 - _selected_side
		_update_labels()
		return true
	if _is_key(key_event, KEY_UP):
		_move_selection(-1)
		return true
	if _is_key(key_event, KEY_DOWN):
		_move_selection(1)
		return true
	if _is_key(key_event, KEY_ENTER) or _is_key(key_event, KEY_KP_ENTER):
		_exchange_selected()
		return true
	return true


func _move_selection(offset: int) -> void:
	if _selected_side == 0:
		if _player_entries.is_empty():
			return
		_player_selected_index = posmod(_player_selected_index + offset, _player_entries.size())
	else:
		if _vendor_entries.is_empty():
			return
		_vendor_selected_index = posmod(_vendor_selected_index + offset, _vendor_entries.size())
	_update_labels()


func _exchange_selected() -> void:
	if _vendor == null or _player_inventory == null:
		return
	if _player_entries.is_empty():
		_set_status("YOU HAVE NOTHING TO OFFER")
		return
	if _vendor_entries.is_empty():
		_set_status("ROOK HAS NOTHING LEFT TO TRADE")
		return

	var offered_entry: Dictionary = _player_entries[_player_selected_index]
	var requested_entry: Dictionary = _vendor_entries[_vendor_selected_index]
	var offered_name: String = _get_entry_name(offered_entry)
	var received_name: String = _get_entry_name(requested_entry)
	if not _vendor.exchange(_player_inventory, offered_entry, requested_entry):
		_set_status("THAT EXCHANGE IS NO LONGER AVAILABLE")
		refresh()
		return

	refresh()
	_set_status("TRADED %s FOR %s" % [offered_name.to_upper(), received_name.to_upper()])
	trade_completed.emit(offered_name, received_name)


func _update_labels() -> void:
	player_offer_label.text = _format_entries(_player_entries, _player_selected_index, _selected_side == 0)
	vendor_stock_label.text = _format_entries(_vendor_entries, _vendor_selected_index, _selected_side == 1)

	var selected_entry: Dictionary = _get_selected_entries()[0]
	var selected_name: String = _get_entry_name(selected_entry)
	var selected_side_name: String = "OFFER" if _selected_side == 0 else "RECEIVE"
	if selected_name.is_empty():
		selected_side_label.text = "%s: NOTHING SELECTED" % selected_side_name
	else:
		selected_side_label.text = "%s: %s" % [selected_side_name, selected_name.to_upper()]
	trade_status_label.text = _status_message


func _format_entries(
	entries: Array[Dictionary],
	selected_index: int,
	is_selected_side: bool,
) -> String:
	if entries.is_empty():
		return "NO ITEMS"

	var lines: PackedStringArray = PackedStringArray()
	for entry_index: int in range(entries.size()):
		var entry: Dictionary = entries[entry_index]
		var marker: String = ">" if is_selected_side and entry_index == selected_index else " "
		var entry_name: String = _get_entry_name(entry).to_upper()
		var weapon_value: Variant = entry.get("weapon", null)
		if weapon_value is WeaponData:
			var weapon: WeaponData = weapon_value as WeaponData
			lines.append("%s %s  %d HEARTS/HIT" % [marker, entry_name, weapon.attack_damage])
		else:
			lines.append("%s %s" % [marker, entry_name])
	return "\n".join(lines)


func _get_selected_entries() -> Array[Dictionary]:
	if _selected_side == 0:
		if _player_entries.is_empty():
			return [{}]
		return [_player_entries[_player_selected_index]]
	if _vendor_entries.is_empty():
		return [{}]
	return [_vendor_entries[_vendor_selected_index]]


func _get_entry_name(entry: Dictionary) -> String:
	return str(entry.get("item_name", "")).strip_edges()


func _set_status(message: String) -> void:
	_status_message = message
	_update_labels()


func _clamp_index(index: int, entry_count: int) -> int:
	if entry_count <= 0:
		return 0
	return clampi(index, 0, entry_count - 1)


func _is_key(key_event: InputEventKey, key_code: int) -> bool:
	return key_event.keycode == key_code or key_event.physical_keycode == key_code
