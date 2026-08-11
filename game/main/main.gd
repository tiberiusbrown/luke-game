extends Node2D

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
@onready var vendor_panel: VendorPanel = $Hud/VendorPanel
@onready var status_log: StatusLog = $Hud/StatusLog
@onready var game_over_panel: Panel = $Hud/GameOverPanel
@onready var game_over_message_label: Label = $Hud/GameOverPanel/MessageLabel
@onready var hireling_prompt_panel: Panel = $Hud/HirelingPromptPanel
@onready var hireling_prompt_label: Label = $Hud/HirelingPromptPanel/PromptLabel
@onready var tutorial_overlay: Control = $Hud/TutorialOverlay
@onready var tutorial_panel: Panel = $Hud/TutorialOverlay/TutorialPanel
@onready var begin_button: Button = $Hud/TutorialOverlay/TutorialPanel/BeginButton
@onready var home_panel: Panel = $Hud/HomePanel
@onready var return_to_game_button: Button = $Hud/HomePanel/ReturnToGameButton
@onready var impossible_trial_button: Button = $Hud/HomePanel/ImpossibleTrialButton

var active_dungeon_level: DungeonLevel
var trial_level: DungeonLevel = null
var _trial_player: DungeonEntity = null
var _trial_return_cell: Vector2i = Vector2i.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	active_dungeon_level = dungeon_level
	set_process_input(true)
	player.inventory.inventory_changed.connect(_on_inventory_changed)
	dungeon_level.item_collected.connect(_on_item_collected)
	dungeon_level.vendor_interaction_requested.connect(_on_vendor_interaction_requested)
	dungeon_level.companion_event.connect(_on_companion_event)
	dungeon_level.prison_event.connect(_on_prison_event)
	dungeon_level.player_control_changed.connect(_on_player_control_changed)
	dungeon_level.game_over.connect(_on_game_over)
	player.inventory.weapon_wielded.connect(_on_weapon_wielded)
	player.inventory.weapon_unwielded.connect(_on_weapon_unwielded)
	player.inventory.weapon_broken.connect(_on_weapon_broken)
	player.healing_item_used.connect(_on_healing_item_used)
	dungeon_level.combat_event.connect(_on_combat_event)
	vendor_panel.trade_completed.connect(_on_vendor_trade_completed)
	vendor_panel.close_requested.connect(_on_vendor_panel_close_requested)
	begin_button.pressed.connect(_on_begin_button_pressed)
	return_to_game_button.pressed.connect(_on_return_to_game_button_pressed)
	impossible_trial_button.pressed.connect(_on_impossible_trial_button_pressed)
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	var active_player: DungeonEntity = dungeon_level.get_player()
	health_bar.bind_health(active_player.health if active_player != null else player.health)
	inventory_panel.refresh(player.inventory)
	wield_panel.refresh(player.inventory)
	status_log.add_message("You enter the dungeon")
	_update_trial_button_state()
	_layout_ui()
	position_label.text = _get_position_text()
	begin_button.grab_focus()


func _process(_delta: float) -> void:
	position_label.text = _get_position_text()
	_update_hireling_notification()


func _on_viewport_size_changed() -> void:
	_layout_ui()


func _layout_ui() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	background.position = Vector2.ZERO
	background.size = viewport_size
	tutorial_overlay.position = Vector2.ZERO
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
	var map_size: Vector2 = active_dungeon_level.get_map_size()
	var map_scale: float = minf(
		map_area.size.x / map_size.x,
		map_area.size.y / map_size.y,
	)
	var scaled_map_size: Vector2 = map_size * map_scale
	active_dungeon_level.scale = Vector2.ONE * map_scale
	active_dungeon_level.position = map_area.position + (map_area.size - scaled_map_size) * 0.5
	_center_panel(inventory_panel, map_area)
	_center_panel(wield_panel, map_area)
	_center_panel(vendor_panel, map_area)
	_center_panel(game_over_panel, map_area)
	_center_panel(home_panel, map_area)
	_position_hireling_prompt(map_area)
	_center_tutorial_panel(viewport_size)

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


func _center_tutorial_panel(viewport_size: Vector2) -> void:
	var panel_size: Vector2 = Vector2(
		minf(600.0, maxf(320.0, viewport_size.x - 32.0)),
		minf(500.0, maxf(400.0, viewport_size.y - 32.0)),
	)
	tutorial_panel.size = panel_size
	tutorial_panel.position = (viewport_size - panel_size) * 0.5


func _position_hireling_prompt(area: Rect2) -> void:
	var prompt_x: float = area.position.x + (area.size.x - hireling_prompt_panel.size.x) * 0.5
	var prompt_y: float = area.position.y + area.size.y - hireling_prompt_panel.size.y - 18.0
	hireling_prompt_panel.position = Vector2(prompt_x, prompt_y)


func _update_hireling_notification() -> void:
	var notification_text: String = active_dungeon_level.get_hireling_notification()
	hireling_prompt_panel.visible = (
		notification_text != ""
		and not game_over_panel.visible
		and not home_panel.visible
	)
	if hireling_prompt_panel.visible:
		hireling_prompt_label.text = notification_text


func _get_position_text() -> String:
	var cell: Vector2i = _get_active_player().get_current_cell()
	return "POSITION  %02d, %02d" % [cell.x, cell.y]


func _input(event: InputEvent) -> void:
	_handle_key_event(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_key_event(event)


func _handle_key_event(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null:
		return
	if tutorial_overlay.visible:
		if key_event.pressed and not key_event.echo and (
			_is_key(key_event, KEY_ENTER)
			or _is_key(key_event, KEY_KP_ENTER)
			or _is_key(key_event, KEY_SPACE)
		):
			_on_begin_button_pressed()
		get_viewport().set_input_as_handled()
		return
	if game_over_panel.visible:
		get_viewport().set_input_as_handled()
		return
	if home_panel.visible:
		get_viewport().set_input_as_handled()
		return

	if vendor_panel.visible:
		if key_event.pressed and not key_event.echo:
			vendor_panel.handle_key(key_event)
		get_viewport().set_input_as_handled()
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
	elif _is_key(key_event, KEY_R):
		player.use_first_healing_item()
		get_viewport().set_input_as_handled()
	elif _is_key(key_event, KEY_H):
		_show_home_screen()
		get_viewport().set_input_as_handled()


func _on_inventory_changed() -> void:
	if inventory_panel.visible:
		inventory_panel.refresh(player.inventory)
	if wield_panel.visible:
		wield_panel.refresh(player.inventory)
	if vendor_panel.visible:
		vendor_panel.refresh()
	_update_trial_button_state()


func _update_trial_button_state() -> void:
	if trial_level != null:
		return
	impossible_trial_button.disabled = (
		player.inventory.get_item_count(DungeonLevel.SKULL_ITEM_NAME) < 5
	)


func _on_item_collected(item_name: String, _cell: Vector2i) -> void:
	status_log.add_message("You pick up the %s" % item_name)


func _on_weapon_wielded(weapon: WeaponData) -> void:
	status_log.add_message("You wield the %s" % weapon.weapon_name)


func _on_weapon_unwielded(weapon: WeaponData) -> void:
	status_log.add_message("You unwield the %s" % weapon.weapon_name)


func _on_weapon_broken(weapon: WeaponData) -> void:
	status_log.add_message("The %s breaks" % weapon.weapon_name)


func _on_healing_item_used(item_name: String, healing_hearts: int) -> void:
	status_log.add_message("You use %s and recover %d hearts" % [item_name, healing_hearts])


func _on_combat_event(message: String) -> void:
	status_log.add_message(message)


func _on_vendor_interaction_requested(vendor: DungeonVendor) -> void:
	inventory_panel.visible = false
	wield_panel.visible = false
	vendor_panel.show_vendor(vendor, player.inventory)


func _on_vendor_trade_completed(offered_name: String, received_name: String) -> void:
	status_log.add_message("Rook trades %s for %s" % [offered_name, received_name])


func _on_vendor_panel_close_requested() -> void:
	vendor_panel.visible = false


func _on_companion_event(message: String) -> void:
	status_log.add_message(message)


func _on_prison_event(message: String) -> void:
	status_log.add_message(message)


func _on_player_control_changed(
	_previous_player: DungeonEntity,
	current_player: DungeonEntity,
) -> void:
	if current_player == null:
		return
	health_bar.bind_health(current_player.health)


func _on_game_over() -> void:
	vendor_panel.visible = false
	inventory_panel.visible = false
	wield_panel.visible = false
	game_over_message_label.text = (
		"You and your fighter have fallen."
		if dungeon_level.is_hireling_hired()
		else "You have fallen."
	)
	game_over_panel.visible = true


func _on_begin_button_pressed() -> void:
	tutorial_overlay.visible = false
	begin_button.release_focus()
	status_log.add_message("Find the key, unlock the Boss Prison, and defeat the Cyclopes")


func _show_home_screen() -> void:
	if trial_level != null or game_over_panel.visible:
		return
	inventory_panel.visible = false
	wield_panel.visible = false
	vendor_panel.visible = false
	home_panel.visible = true
	get_tree().paused = true
	return_to_game_button.grab_focus()


func _on_return_to_game_button_pressed() -> void:
	home_panel.visible = false
	get_tree().paused = false


func _on_impossible_trial_button_pressed() -> void:
	if trial_level != null:
		return
	if player.inventory.get_item_count(DungeonLevel.SKULL_ITEM_NAME) < 5:
		status_log.add_message("You need 5 skulls to enter the Impossible Trial")
		return
	_start_impossible_trial()


func _start_impossible_trial() -> void:
	home_panel.visible = false
	get_tree().paused = false
	var current_player: DungeonEntity = _get_active_player()
	if current_player == null:
		return
	_trial_player = current_player
	_trial_return_cell = current_player.current_cell
	dungeon_level.suspend_player(current_player)
	dungeon_level.process_mode = Node.PROCESS_MODE_DISABLED
	dungeon_level.visible = false
	if player.get_parent() == dungeon_level:
		dungeon_level.remove_child(player)
	if current_player.get_parent() == dungeon_level:
		dungeon_level.remove_child(current_player)

	trial_level = DungeonLevel.new()
	trial_level.configure_impossible_trial()
	trial_level.trial_completed.connect(_on_trial_completed)
	trial_level.game_over.connect(_on_trial_game_over)
	add_child(trial_level)
	trial_level.add_child(current_player)
	trial_level.attach_player(current_player, trial_level.get_start_cell())
	if current_player != player:
		# DungeonPlayer owns the shared keyboard input and acts as a hidden input
		# proxy while the hired fighter is the active trial character.
		trial_level.add_child(player)
		player.setup(trial_level, trial_level.get_start_cell())
		player.visible = false
	trial_level.visible = true
	active_dungeon_level = trial_level
	impossible_trial_button.disabled = true
	status_log.add_message("The Impossible Trial begins: defeat 10 Cyclopes")
	_layout_ui()


func _on_trial_completed() -> void:
	if trial_level == null or _trial_player == null:
		return

	var finished_trial: DungeonLevel = trial_level
	finished_trial.suspend_player(_trial_player)
	finished_trial.remove_child(_trial_player)
	if player.get_parent() == finished_trial:
		finished_trial.remove_child(player)
	finished_trial.queue_free()
	trial_level = null

	dungeon_level.add_child(_trial_player)
	dungeon_level.process_mode = Node.PROCESS_MODE_INHERIT
	dungeon_level.visible = true
	dungeon_level.attach_player(_trial_player, _trial_return_cell)
	_trial_player.health.set_max_hearts(20, true)
	if _trial_player != player:
		dungeon_level.add_child(player)
		player.setup(dungeon_level, _trial_return_cell)
		player.visible = false
	_trial_player = null
	dungeon_level.respawn_all_mobs()
	active_dungeon_level = dungeon_level
	impossible_trial_button.disabled = false
	status_log.add_message("Impossible Trial defeated. You return with 20 hearts.")
	_layout_ui()


func _on_trial_game_over() -> void:
	get_tree().paused = false
	home_panel.visible = false
	_on_game_over()


func _get_active_player() -> DungeonEntity:
	var active_player: DungeonEntity = active_dungeon_level.get_player()
	return active_player if active_player != null else player


func _is_key(key_event: InputEventKey, key_code: int) -> bool:
	return key_event.keycode == key_code or key_event.physical_keycode == key_code
