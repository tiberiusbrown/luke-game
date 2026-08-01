extends Node2D

@onready var dungeon_level: DungeonLevel = $DungeonLevel
@onready var player: DungeonPlayer = $DungeonLevel/Player
@onready var position_label: Label = $Hud/PositionLabel
@onready var health_bar: HeartHealthBar = $Hud/HealthBar
@onready var inventory_panel: InventoryPanel = $Hud/InventoryPanel


func _ready() -> void:
	player.inventory.inventory_changed.connect(_on_inventory_changed)
	health_bar.bind_health(player.health)
	inventory_panel.refresh(player.inventory)
	position_label.text = _get_position_text()


func _process(_delta: float) -> void:
	position_label.text = _get_position_text()


func _get_position_text() -> String:
	var cell: Vector2i = player.get_current_cell()
	return "POSITION  %02d, %02d" % [cell.x, cell.y]


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if key_event.keycode != KEY_I and key_event.physical_keycode != KEY_I:
		return

	inventory_panel.visible = not inventory_panel.visible
	inventory_panel.refresh(player.inventory)
	get_viewport().set_input_as_handled()


func _on_inventory_changed() -> void:
	if inventory_panel.visible:
		inventory_panel.refresh(player.inventory)
