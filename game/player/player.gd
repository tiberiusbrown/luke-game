class_name DungeonPlayer
extends CharacterBody2D

const MOVE_DURATION: float = 0.14
const MAX_HEARTS: int = 10

var dungeon_level: DungeonLevel
var inventory: PlayerInventory = PlayerInventory.new()
var health: HeartHealth = HeartHealth.new(MAX_HEARTS)
var current_cell: Vector2i = Vector2i.ZERO
var is_moving: bool = false
var _move_tween: Tween


func _ready() -> void:
	z_index = 2
	dungeon_level = get_parent() as DungeonLevel
	if dungeon_level == null:
		return

	current_cell = dungeon_level.get_start_cell()
	position = dungeon_level.cell_to_world(current_cell)
	velocity = Vector2.ZERO
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return

	var direction: Vector2i = _get_direction_for_key(key_event)
	if direction != Vector2i.ZERO:
		try_move(direction)


func try_move(direction: Vector2i) -> bool:
	if dungeon_level == null or is_moving or health.is_depleted():
		return false
	if not _is_cardinal_direction(direction):
		return false

	var target_cell: Vector2i = current_cell + direction
	if not dungeon_level.is_walkable(target_cell):
		return false

	var target_position: Vector2 = dungeon_level.cell_to_world(target_cell)
	current_cell = target_cell
	is_moving = true
	velocity = Vector2.ZERO

	if is_instance_valid(_move_tween):
		_move_tween.kill()
	_move_tween = create_tween()
	_move_tween.set_trans(Tween.TRANS_SINE)
	_move_tween.set_ease(Tween.EASE_OUT)
	_move_tween.tween_property(self, "position", target_position, MOVE_DURATION)
	_move_tween.tween_callback(_finish_move)
	return true


func get_current_cell() -> Vector2i:
	return current_cell


func take_damage(damage_hearts: int) -> int:
	var damage_dealt: int = health.take_damage(damage_hearts)
	if health.is_depleted():
		velocity = Vector2.ZERO
	return damage_dealt


func heal(healing_hearts: int) -> int:
	return health.heal(healing_hearts)


func get_attack_damage() -> int:
	var weapon: WeaponData = inventory.get_equipped_weapon()
	if weapon == null:
		return 0
	return weapon.attack_damage


func _finish_move() -> void:
	if dungeon_level != null:
		position = dungeon_level.cell_to_world(current_cell)
		_collect_item_at_current_cell()
	is_moving = false
	velocity = Vector2.ZERO


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


func _is_cardinal_direction(direction: Vector2i) -> bool:
	return abs(direction.x) + abs(direction.y) == 1


func _draw() -> void:
	draw_circle(Vector2(2, 4), 11.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(Vector2.ZERO, 10.0, Color("#e7eef4"))
	draw_circle(Vector2.ZERO, 8.0, Color("#68a7d8"))
	draw_circle(Vector2(-3, -2), 1.5, Color("#f5f7fa"))
	draw_circle(Vector2(3, -2), 1.5, Color("#f5f7fa"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("#b9d4e8"), 2.0)
