extends Node2D

const MAP_SIZE: Vector2 = Vector2(
	DungeonLevel.GRID_WIDTH * DungeonLevel.TILE_SIZE,
	DungeonLevel.GRID_HEIGHT * DungeonLevel.TILE_SIZE,
)
const TOP_BAR_HEIGHT: float = 64.0
const LAYOUT_MARGIN: float = 16.0
const PANEL_GAP: float = 16.0
const STATUS_PANEL_WIDTH: float = 224.0
const POSITION_LABEL_WIDTH: float = 144.0

@onready var background: ColorRect = $Background
@onready var dungeon_level: DungeonLevel = $DungeonLevel
@onready var player: DungeonPlayer = $DungeonLevel/Player
@onready var top_bar: ColorRect = $Hud/TopBar
@onready var position_label: Label = $Hud/PositionLabel
@onready var health_bar: HeartHealthBar = $Hud/HealthBar
@onready var inventory_panel: InventoryPanel = $Hud/InventoryPanel
@onready var wield_panel: WieldPanel = $Hud/WieldPanel
@onready var status_log: StatusLog = $Hud/StatusLog


func _ready() -> void:
	set_process_input(true)
	player.inventory.inventory_changed.connect(_on_inventory_changed)
	dungeon_level.item_collected.connect(_on_item_collected)
	player.inventory.weapon_wielded.connect(_on_weapon_wielded)
	player.inventory.weapon_unwielded.connect(_on_weapon_unwielded)
	dungeon_level.combat_event.connect(_on_combat_event)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	health_bar.bind_health(player.health)
	inventory_panel.refresh(player.inventory)
	wield_panel.refresh(player.inventory)
	status_log.add_message("You enter the dungeon")
	_layout_ui()
	position_label.text = _get_position_text()


func _process(_delta: float) -> void:
	position_label.text = _get_position_text()


func _on_viewport_size_changed() -> void:
	_layout_ui()


func _layout_ui() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	background.position = Vector2.ZERO
	background.size = viewport_size
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(viewport_size.x, TOP_BAR_HEIGHT)

	var status_width: float = minf(
		STATUS_PANEL_WIDTH,
		maxf(1.0, viewport_size.x - 2.0 * LAYOUT_MARGIN),
	)
	var status_left: float = viewport_size.x - LAYOUT_MARGIN - status_width
	var status_top: float = TOP_BAR_HEIGHT + LAYOUT_MARGIN
	var status_bottom: float = maxf(status_top + 1.0, viewport_size.y - LAYOUT_MARGIN)
	status_log.position = Vector2(status_left, status_top)
	status_log.size = Vector2(status_width, status_bottom - status_top)

	var map_area: Rect2 = Rect2(
		Vector2(LAYOUT_MARGIN, status_top),
		Vector2(
			maxf(1.0, status_left - PANEL_GAP - LAYOUT_MARGIN),
			maxf(1.0, status_bottom - status_top),
		),
	)
	var map_scale: float = minf(
		map_area.size.x / MAP_SIZE.x,
		map_area.size.y / MAP_SIZE.y,
	)
	var scaled_map_size: Vector2 = MAP_SIZE * map_scale
	dungeon_level.scale = Vector2.ONE * map_scale
	dungeon_level.position = map_area.position + (map_area.size - scaled_map_size) * 0.5
	_center_panel(inventory_panel, map_area)
	_center_panel(wield_panel, map_area)

	var position_left: float = maxf(
		LAYOUT_MARGIN,
		viewport_size.x - LAYOUT_MARGIN - POSITION_LABEL_WIDTH,
	)
	position_label.position = Vector2(position_left, 25.0)
	position_label.size = Vector2(
		maxf(1.0, viewport_size.x - LAYOUT_MARGIN - position_left),
		23.0,
	)


func _center_panel(panel: Control, area: Rect2) -> void:
	var centered_position: Vector2 = area.position + (area.size - panel.size) * 0.5
	panel.position = centered_position


func _get_position_text() -> String:
	var cell: Vector2i = player.get_current_cell()
	return "POSITION  %02d, %02d" % [cell.x, cell.y]


func _input(event: InputEvent) -> void:
	_handle_key_event(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_key_event(event)


func _handle_key_event(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null:
		return

	if inventory_panel.visible or wield_panel.visible:
		if key_event.pressed and not key_event.echo:
			if inventory_panel.visible and _is_key(key_event, KEY_I):
				inventory_panel.visible = false
			elif wield_panel.visible and _is_key(key_event, KEY_W):
				wield_panel.visible = false
			elif wield_panel.visible:
				wield_panel.handle_key(key_event)
			elif _is_key(key_event, KEY_ESCAPE):
				inventory_panel.visible = false
		get_viewport().set_input_as_handled()
		return

	if not key_event.pressed or key_event.echo:
		return
	if _is_key(key_event, KEY_I):
		inventory_panel.visible = true
		wield_panel.visible = false
		inventory_panel.refresh(player.inventory)
		get_viewport().set_input_as_handled()
	elif _is_key(key_event, KEY_W):
		wield_panel.visible = true
		inventory_panel.visible = false
		wield_panel.refresh(player.inventory)
		get_viewport().set_input_as_handled()


func _on_inventory_changed() -> void:
	if inventory_panel.visible:
		inventory_panel.refresh(player.inventory)
	if wield_panel.visible:
		wield_panel.refresh(player.inventory)


func _on_item_collected(item_name: String, _cell: Vector2i) -> void:
	status_log.add_message("You pick up the %s" % item_name)


func _on_weapon_wielded(weapon: WeaponData) -> void:
	status_log.add_message("You wield the %s" % weapon.weapon_name)


func _on_weapon_unwielded(weapon: WeaponData) -> void:
	status_log.add_message("You unwield the %s" % weapon.weapon_name)


func _on_combat_event(message: String) -> void:
	status_log.add_message(message)


func _is_key(key_event: InputEventKey, key_code: int) -> bool:
	return key_event.keycode == key_code or key_event.physical_keycode == key_code
