class_name DungeonEntity
extends CharacterBody2D

signal action_finished(entity: DungeonEntity)
signal movement_started(entity: DungeonEntity, from_cell: Vector2i, to_cell: Vector2i)
signal movement_finished(entity: DungeonEntity, cell: Vector2i)
signal attack_started(attacker: DungeonEntity, target: DungeonEntity)
signal attack_landed(attacker: DungeonEntity, target: DungeonEntity, damage: int)
signal attack_missed(attacker: DungeonEntity, target: DungeonEntity)
signal damage_taken(entity: DungeonEntity, damage: int, remaining_hearts: int)
signal defeated(entity: DungeonEntity)

const DEFAULT_MAX_HEARTS: int = 10
const MOVE_DURATION: float = 0.14
const ATTACK_LUNGE_DURATION: float = 0.08
const ATTACK_RETURN_DURATION: float = 0.12
const CATCH_UP_ANIMATION_SPEED_SCALE: float = 4.0

var dungeon_level: DungeonLevel = null
var current_cell: Vector2i = Vector2i.ZERO
var speed: float = 1.0
var health: HeartHealth = null
var is_moving: bool = false
var is_attacking: bool = false
var random_number_generator: RandomNumberGenerator = RandomNumberGenerator.new()

var _action_tween: Tween = null
var _feedback_tween: Tween = null


func _init() -> void:
	health = HeartHealth.new(DEFAULT_MAX_HEARTS)
	random_number_generator.randomize()


func _ready() -> void:
	z_index = 2
	if dungeon_level == null:
		dungeon_level = get_parent() as DungeonLevel


func setup(new_dungeon_level: DungeonLevel, new_cell: Vector2i) -> void:
	dungeon_level = new_dungeon_level
	current_cell = new_cell
	if dungeon_level != null:
		position = dungeon_level.cell_to_world(current_cell)


func try_move(direction: Vector2i) -> bool:
	if not _can_start_action() or not _is_cardinal_direction(direction):
		return false
	if dungeon_level == null:
		return false

	var target_cell: Vector2i = current_cell + direction
	var target_is_walkable: bool = dungeon_level.is_walkable(target_cell)
	if is_player_entity():
		target_is_walkable = dungeon_level.can_player_move_to(current_cell, target_cell)
	if not target_is_walkable:
		return false

	var target_entity: DungeonEntity = dungeon_level.get_entity_at(target_cell)
	if target_entity != null and target_entity != self:
		if is_player_entity() and target_entity.can_be_passed_through_by_player():
			return _try_swap_with_entity(target_entity)
		return _try_attack(target_entity)
	if not _begin_action():
		return false
	return _start_movement(target_cell)


func get_current_cell() -> Vector2i:
	return current_cell


func get_attack_damage() -> int:
	return 0


func get_attack_range() -> int:
	return 1


func get_hit_chance() -> float:
	return 1.0


func get_display_name() -> String:
	return "Entity"


func get_attack_color() -> Color:
	return Color("#f2c879")


func is_player_entity() -> bool:
	return false


func can_be_passed_through_by_player() -> bool:
	return false


func take_damage(damage_hearts: int) -> int:
	if health == null:
		return 0

	var damage_dealt: int = health.take_damage(damage_hearts)
	if damage_dealt <= 0:
		return 0

	_play_damage_feedback()
	damage_taken.emit(self, damage_dealt, health.current_hearts)
	if dungeon_level != null:
		dungeon_level.spawn_hit_effect(current_cell, damage_dealt, get_attack_color())
	if health.is_depleted():
		defeated.emit(self)
		_on_defeated()
	return damage_dealt


func set_random_seed(random_seed: int) -> void:
	random_number_generator.seed = random_seed


func is_action_in_progress() -> bool:
	return is_moving or is_attacking


func speed_up_action_animation() -> void:
	if not is_instance_valid(_action_tween) or not _action_tween.is_running():
		return
	_action_tween.set_speed_scale(CATCH_UP_ANIMATION_SPEED_SCALE)


func _can_start_action() -> bool:
	return health != null and not health.is_depleted() and not is_action_in_progress()


func _begin_action() -> bool:
	if dungeon_level != null and is_player_entity():
		return dungeon_level.begin_player_action(self)
	return true


func _start_movement(target_cell: Vector2i) -> bool:
	var from_cell: Vector2i = current_cell
	var target_position: Vector2 = dungeon_level.cell_to_world(target_cell)
	current_cell = target_cell
	is_moving = true
	velocity = Vector2.ZERO
	movement_started.emit(self, from_cell, target_cell)

	_kill_action_tween()
	_action_tween = create_tween()
	_action_tween.set_trans(Tween.TRANS_SINE)
	_action_tween.set_ease(Tween.EASE_OUT)
	_action_tween.tween_property(self, "position", target_position, MOVE_DURATION)
	_action_tween.tween_callback(_finish_movement)
	return true


func _try_attack(target: DungeonEntity) -> bool:
	if target == null or not is_instance_valid(target) or target.health.is_depleted():
		return false
	if not _can_attack_target(target):
		return false
	if not _is_in_attack_range(target.current_cell):
		return false
	if not _begin_action():
		return false

	is_attacking = true
	velocity = Vector2.ZERO
	attack_started.emit(self, target)
	var starting_position: Vector2 = position
	var target_position: Vector2 = dungeon_level.cell_to_world(target.current_cell)
	var lunge_position: Vector2 = starting_position.lerp(target_position, 0.38)

	_kill_action_tween()
	_action_tween = create_tween()
	_action_tween.set_trans(Tween.TRANS_SINE)
	_action_tween.set_ease(Tween.EASE_OUT)
	_action_tween.tween_property(self, "position", lunge_position, ATTACK_LUNGE_DURATION)
	_action_tween.tween_callback(Callable(self, "_resolve_attack").bind(target))
	_action_tween.tween_property(self, "position", starting_position, ATTACK_RETURN_DURATION)
	_action_tween.tween_callback(_finish_attack)
	return true


func _try_swap_with_entity(target: DungeonEntity) -> bool:
	if (
		target == null
		or not is_instance_valid(target)
		or target.is_action_in_progress()
		or dungeon_level == null
	):
		return false
	if not _begin_action():
		return false

	var from_cell: Vector2i = current_cell
	var target_cell: Vector2i = target.current_cell
	target.current_cell = from_cell
	target.position = dungeon_level.cell_to_world(from_cell)
	target.velocity = Vector2.ZERO
	return _start_movement(target_cell)


func _resolve_attack(target: DungeonEntity) -> void:
	if (
		dungeon_level == null
		or health == null
		or health.is_depleted()
		or target == null
		or not is_instance_valid(target)
		or target.dungeon_level != dungeon_level
		or target.health == null
		or target.health.is_depleted()
		or not _is_in_attack_range(target.current_cell)
	):
		return

	var hit_chance: float = clampf(get_hit_chance(), 0.0, 1.0)
	if random_number_generator.randf() >= hit_chance:
		attack_missed.emit(self, target)
		if dungeon_level != null:
			dungeon_level.report_attack(self, target, false, 0)
		return

	var damage_dealt: int = target.take_damage(get_attack_damage())
	if damage_dealt > 0:
		attack_landed.emit(self, target, damage_dealt)
		_after_attack_landed(target, damage_dealt)
		if dungeon_level != null:
			dungeon_level.report_attack(self, target, true, damage_dealt)


func _finish_movement() -> void:
	if dungeon_level != null:
		position = dungeon_level.cell_to_world(current_cell)
	is_moving = false
	velocity = Vector2.ZERO
	_after_move()
	movement_finished.emit(self, current_cell)
	action_finished.emit(self)


func _finish_attack() -> void:
	if dungeon_level != null:
		position = dungeon_level.cell_to_world(current_cell)
	is_attacking = false
	velocity = Vector2.ZERO
	action_finished.emit(self)


func _after_move() -> void:
	pass


func _after_attack_landed(_target: DungeonEntity, _damage: int) -> void:
	pass


func get_held_weapon() -> WeaponData:
	return null


func _draw_held_weapon() -> void:
	var weapon: WeaponData = get_held_weapon()
	if weapon == null:
		return

	var weapon_color: Color = Color("#d08d5c") if weapon.get_material_name() == "gold" else Color("#c7cedc")
	var weapon_shadow: Color = weapon_color.darkened(0.35)
	var weapon_kind: String = weapon.weapon_name.to_lower()
	if weapon_kind.contains("spear"):
		draw_line(Vector2(7, 4), Vector2(18, -10), weapon_shadow, 3.0)
		draw_line(Vector2(8, 3), Vector2(18, -10), weapon_color, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(18, -14), Vector2(21, -8), Vector2(16, -9)]), weapon_color)
	elif weapon_kind.contains("axe"):
		draw_line(Vector2(7, 5), Vector2(17, -8), weapon_shadow, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(13, -11), Vector2(21, -9), Vector2(19, -2), Vector2(14, -4)]), weapon_color)
	elif weapon_kind.contains("mace") or weapon_kind.contains("hammer"):
		draw_line(Vector2(7, 5), Vector2(16, -6), weapon_shadow, 3.0)
		draw_circle(Vector2(18, -9), 4.0, weapon_color)
		draw_circle(Vector2(18, -9), 2.0, weapon_color.lightened(0.25))
	elif weapon_kind.contains("dagger"):
		draw_line(Vector2(7, 5), Vector2(15, -3), weapon_shadow, 3.0)
		draw_colored_polygon(PackedVector2Array([Vector2(13, -5), Vector2(21, -9), Vector2(16, -2)]), weapon_color)
	else:
		draw_line(Vector2(7, 5), Vector2(19, -9), weapon_shadow, 4.0)
		draw_line(Vector2(8, 4), Vector2(19, -9), weapon_color, 2.0)
		draw_line(Vector2(8, 1), Vector2(13, 5), weapon_color, 2.0)


func _can_attack_target(_target: DungeonEntity) -> bool:
	return true


func _on_defeated() -> void:
	pass


func _play_damage_feedback() -> void:
	if not is_inside_tree():
		return
	if is_instance_valid(_feedback_tween):
		_feedback_tween.kill()
	modulate = Color(1.0, 0.72, 0.72, 1.0)
	_feedback_tween = create_tween()
	_feedback_tween.set_trans(Tween.TRANS_SINE)
	_feedback_tween.tween_property(self, "modulate", Color.WHITE, 0.16)


func _kill_action_tween() -> void:
	if is_instance_valid(_action_tween):
		_action_tween.kill()


func _are_adjacent(target_cell: Vector2i) -> bool:
	var difference: Vector2i = target_cell - current_cell
	return abs(difference.x) + abs(difference.y) == 1


func _is_in_attack_range(target_cell: Vector2i) -> bool:
	var difference: Vector2i = target_cell - current_cell
	var distance: int = abs(difference.x) + abs(difference.y)
	return distance > 0 and distance <= get_attack_range()


func _is_cardinal_direction(direction: Vector2i) -> bool:
	return abs(direction.x) + abs(direction.y) == 1
