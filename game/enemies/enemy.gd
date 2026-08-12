class_name DungeonEnemy
extends DungeonEntity

const MAX_HEARTS: int = 10

var enemy_type: String = "Enemy"
var attack_damage: int = 1
var hit_chance: float = 1.0
var is_boss: bool = false
var _base_attack_damage: int = 1


func _init() -> void:
	super._init()
	health = HeartHealth.new(MAX_HEARTS)


func _ready() -> void:
	super._ready()
	if dungeon_level == null:
		return
	if not dungeon_level.entities.has(self):
		dungeon_level.register_entity(self)
	queue_redraw()


func take_turn() -> bool:
	if health.is_depleted() or is_action_in_progress() or dungeon_level == null:
		return false

	var target: DungeonEntity = dungeon_level.get_player()
	if target == null or target.health.is_depleted():
		return false
	if (
		dungeon_level.is_safe_area_cell(target.current_cell)
		and not dungeon_level.is_safe_area_cell(current_cell)
	):
		return false
	if _is_in_attack_range(target.current_cell):
		return _try_attack(target)

	var directions: Array[Vector2i] = _get_chase_directions(target.current_cell)
	for direction: Vector2i in directions:
		var target_cell: Vector2i = current_cell + direction
		if dungeon_level.is_safe_area_cell(target_cell):
			continue
		var occupying_entity: DungeonEntity = dungeon_level.get_entity_at(target_cell)
		if not dungeon_level.is_walkable(target_cell) and occupying_entity == null:
			continue
		if try_move(direction):
			return true
	return false


func get_attack_damage() -> int:
	return attack_damage


func apply_difficulty_damage_modifier(damage_modifier: int) -> void:
	attack_damage = maxi(_base_attack_damage + damage_modifier, 0)


func remember_base_attack_damage() -> void:
	_base_attack_damage = attack_damage


func get_hit_chance() -> float:
	return hit_chance


func get_display_name() -> String:
	return enemy_type


func _can_attack_target(target: DungeonEntity) -> bool:
	if target == null or dungeon_level == null:
		return false
	return target == dungeon_level.get_player()


func _get_chase_directions(target_cell: Vector2i) -> Array[Vector2i]:
	var directions: Array[Vector2i] = []
	var difference: Vector2i = target_cell - current_cell
	var horizontal_direction: Vector2i = Vector2i(signi(difference.x), 0)
	var vertical_direction: Vector2i = Vector2i(0, signi(difference.y))

	if abs(difference.x) >= abs(difference.y):
		if horizontal_direction != Vector2i.ZERO:
			directions.append(horizontal_direction)
		if vertical_direction != Vector2i.ZERO:
			directions.append(vertical_direction)
	else:
		if vertical_direction != Vector2i.ZERO:
			directions.append(vertical_direction)
		if horizontal_direction != Vector2i.ZERO:
			directions.append(horizontal_direction)

	return directions


func _on_defeated() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)
	if dungeon_level != null:
		dungeon_level.unregister_entity(self)
	queue_free()
