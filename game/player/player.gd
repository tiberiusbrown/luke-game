class_name DungeonPlayer
extends DungeonEntity

const MAX_HEARTS: int = 10
const BASE_ATTACK_DAMAGE: int = 1
const HIT_CHANCE: float = 0.80
const SPEED: float = 1.0

var inventory: PlayerInventory = PlayerInventory.new()
var hit_chance: float = HIT_CHANCE
var is_controlled: bool = true


func _init() -> void:
	super._init()
	health = HeartHealth.new(MAX_HEARTS)
	speed = SPEED


func _ready() -> void:
	super._ready()
	if dungeon_level == null:
		return

	if dungeon_level.get_player() == null:
		dungeon_level.set_initial_player(self)

	current_cell = dungeon_level.get_start_cell()
	position = dungeon_level.cell_to_world(current_cell)
	velocity = Vector2.ZERO
	if not dungeon_level.entities.has(self):
		dungeon_level.register_entity(self)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	if dungeon_level == null:
		return

	var active_player: DungeonEntity = dungeon_level.get_player()
	if active_player == null:
		return

	if _is_key(key_event, KEY_E):
		if dungeon_level.interact_with_vendor(active_player.current_cell):
			get_viewport().set_input_as_handled()
		elif dungeon_level.interact_with_hireling(active_player.current_cell, inventory):
			get_viewport().set_input_as_handled()
		elif dungeon_level.interact_with_prison(active_player.current_cell, inventory):
			get_viewport().set_input_as_handled()
		return

	var direction: Vector2i = _get_direction_for_key(key_event)
	if direction != Vector2i.ZERO:
		if dungeon_level.get_vendor_at(active_player.current_cell + direction) != null:
			return
		active_player.try_move(direction)


func get_attack_damage() -> int:
	var weapon: WeaponData = inventory.get_equipped_weapon()
	if weapon == null:
		return BASE_ATTACK_DAMAGE
	return BASE_ATTACK_DAMAGE + weapon.attack_damage


func get_hit_chance() -> float:
	return hit_chance


func get_display_name() -> String:
	return "You"


func get_attack_color() -> Color:
	return Color("#68a7d8")


func set_controlled(controlled: bool) -> void:
	is_controlled = controlled
	queue_redraw()


func is_player_entity() -> bool:
	return is_controlled


func _can_attack_target(target: DungeonEntity) -> bool:
	return target is DungeonEnemy


func heal(healing_hearts: int) -> int:
	return health.heal(healing_hearts)


func _after_move() -> void:
	_collect_item_at_current_cell()


func _collect_item_at_current_cell() -> void:
	if dungeon_level == null:
		return

	var pickup: ItemPickup = dungeon_level.collect_pickup_at(current_cell)
	if pickup == null:
		return
	if pickup.weapon_data != null:
		inventory.add_weapon(pickup.weapon_data)
	else:
		inventory.add_item(pickup.item_name)


func _get_direction_for_key(key_event: InputEventKey) -> Vector2i:
	if key_event.keycode == KEY_LEFT or key_event.physical_keycode == KEY_LEFT:
		return Vector2i(-1, 0)
	if key_event.keycode == KEY_RIGHT or key_event.physical_keycode == KEY_RIGHT:
		return Vector2i(1, 0)
	if key_event.keycode == KEY_UP or key_event.physical_keycode == KEY_UP:
		return Vector2i(0, -1)
	if key_event.keycode == KEY_DOWN or key_event.physical_keycode == KEY_DOWN:
		return Vector2i(0, 1)
	if key_event.keycode == KEY_A or key_event.physical_keycode == KEY_A:
		return Vector2i(-1, 0)
	if key_event.keycode == KEY_D or key_event.physical_keycode == KEY_D:
		return Vector2i(1, 0)
	if key_event.keycode == KEY_S or key_event.physical_keycode == KEY_S:
		return Vector2i(0, 1)
	return Vector2i.ZERO


func _is_key(key_event: InputEventKey, key_code: int) -> bool:
	return key_event.keycode == key_code or key_event.physical_keycode == key_code


func _draw() -> void:
	draw_circle(Vector2(2, 4), 11.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(Vector2.ZERO, 10.0, Color("#e7eef4"))
	draw_circle(Vector2.ZERO, 8.0, Color("#68a7d8"))
	draw_circle(Vector2(-3, -2), 1.5, Color("#f5f7fa"))
	draw_circle(Vector2(3, -2), 1.5, Color("#f5f7fa"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("#b9d4e8"), 2.0)
