class_name DungeonHireling
extends DungeonEntity

const MAX_HEARTS: int = 13
const ATTACK_DAMAGE: int = 3
const HIT_CHANCE: float = 1.0
const SPEED: float = 1.0
const FOLLOW_DISTANCE: int = 1

var is_hired: bool = false
var is_controlled: bool = false
var hit_chance: float = HIT_CHANCE
var inventory: PlayerInventory = PlayerInventory.new()


func _init() -> void:
	super._init()
	health = HeartHealth.new(MAX_HEARTS)
	speed = SPEED
	inventory.inventory_changed.connect(_on_inventory_changed)


func _ready() -> void:
	super._ready()
	if dungeon_level == null:
		return
	if not dungeon_level.entities.has(self):
		dungeon_level.register_entity(self)
	queue_redraw()


func hire() -> void:
	is_hired = true
	queue_redraw()


func set_controlled(controlled: bool) -> void:
	is_controlled = controlled
	queue_redraw()


func set_inventory(new_inventory: PlayerInventory) -> void:
	if new_inventory == null:
		return
	if inventory != new_inventory and inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.disconnect(_on_inventory_changed)
	inventory = new_inventory
	if not inventory.inventory_changed.is_connected(_on_inventory_changed):
		inventory.inventory_changed.connect(_on_inventory_changed)
	queue_redraw()


func take_turn() -> bool:
	if not is_hired or is_controlled or health.is_depleted() or dungeon_level == null:
		return false
	if is_action_in_progress():
		return false

	var target_enemy: DungeonEnemy = _get_nearest_enemy()
	if target_enemy != null:
		var direction_to_enemy: Vector2i = _get_next_step_toward(target_enemy.current_cell)
		if direction_to_enemy != Vector2i.ZERO and try_move(direction_to_enemy):
			return true
		return false

	var player: DungeonEntity = dungeon_level.get_player()
	if player == null or player == self:
		return false
	if _get_manhattan_distance(current_cell, player.current_cell) <= FOLLOW_DISTANCE:
		return false

	var direction_to_player: Vector2i = _get_next_step_toward(player.current_cell)
	return direction_to_player != Vector2i.ZERO and try_move(direction_to_player)


func get_attack_damage() -> int:
	return ATTACK_DAMAGE


func get_held_weapon() -> WeaponData:
	return inventory.get_equipped_weapon()


func get_hit_chance() -> float:
	return hit_chance


func get_display_name() -> String:
	return "Hired Fighter"


func is_player_entity() -> bool:
	return is_controlled


func can_be_passed_through_by_player() -> bool:
	return not is_controlled


func get_attack_color() -> Color:
	return Color("#d6a85f")


func _can_attack_target(target: DungeonEntity) -> bool:
	return target is DungeonEnemy or target is MonsterSpawner


func _after_move() -> void:
	if dungeon_level == null or inventory == null:
		return

	var pickup: ItemPickup = dungeon_level.collect_pickup_at(current_cell)
	if pickup == null:
		return
	if pickup.weapon_data != null:
		inventory.add_weapon(pickup.weapon_data)
	else:
		inventory.add_item(pickup.item_name)


func _after_attack_landed(_target: DungeonEntity, _damage: int) -> void:
	inventory.consume_equipped_weapon_hit()


func _get_nearest_enemy() -> DungeonEnemy:
	if dungeon_level == null:
		return null

	var nearest_enemy: DungeonEnemy = null
	var nearest_distance: int = 2147483647
	for enemy: DungeonEnemy in dungeon_level.enemies:
		if not is_instance_valid(enemy) or enemy.health.is_depleted():
			continue
		var distance: int = _get_manhattan_distance(current_cell, enemy.current_cell)
		if distance < nearest_distance:
			nearest_enemy = enemy
			nearest_distance = distance
	return nearest_enemy


func _get_next_step_toward(target_cell: Vector2i) -> Vector2i:
	if dungeon_level == null or current_cell == target_cell:
		return Vector2i.ZERO

	var frontier: Array[Vector2i] = [current_cell]
	var came_from: Dictionary = {current_cell: current_cell}
	var frontier_index: int = 0
	while frontier_index < frontier.size():
		var search_cell: Vector2i = frontier[frontier_index]
		frontier_index += 1
		for direction: Vector2i in _get_cardinal_directions():
			var next_cell: Vector2i = search_cell + direction
			if came_from.has(next_cell) or not dungeon_level.is_walkable(next_cell):
				continue

			var occupying_entity: DungeonEntity = dungeon_level.get_entity_at(next_cell)
			if occupying_entity != null and next_cell != target_cell:
				continue

			came_from[next_cell] = search_cell
			if next_cell == target_cell:
				return _get_first_step(next_cell, came_from)
			frontier.append(next_cell)

	return Vector2i.ZERO


func _get_first_step(target_cell: Vector2i, came_from: Dictionary) -> Vector2i:
	var path_cell: Vector2i = target_cell
	while came_from.has(path_cell):
		var previous_cell: Vector2i = Vector2i(came_from[path_cell])
		if previous_cell == current_cell:
			return path_cell - current_cell
		path_cell = previous_cell
	return Vector2i.ZERO


func _get_cardinal_directions() -> Array[Vector2i]:
	return [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]


func _get_manhattan_distance(first_cell: Vector2i, second_cell: Vector2i) -> int:
	var difference: Vector2i = second_cell - first_cell
	return abs(difference.x) + abs(difference.y)


func _on_inventory_changed() -> void:
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(2, 6), 12.0, Color(0.0, 0.0, 0.0, 0.34))

	var armor_color: Color = Color("#a67c39")
	var armor_highlight: Color = Color("#e4c16d")
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10, 10),
			Vector2(-8, -2),
			Vector2(-5, -7),
			Vector2(5, -7),
			Vector2(8, -2),
			Vector2(10, 10),
		]),
		armor_color.darkened(0.3),
	)
	draw_polyline(
		PackedVector2Array([
			Vector2(-10, 10),
			Vector2(-8, -2),
			Vector2(-5, -7),
			Vector2(5, -7),
			Vector2(8, -2),
			Vector2(10, 10),
		]),
		armor_highlight,
		2.0,
	)
	draw_circle(Vector2.ZERO, 7.5, Color("#d49b6a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-9, -4),
			Vector2(0, -12),
			Vector2(9, -4),
			Vector2(6, -1),
			Vector2(-6, -1),
		]),
		Color("#4e5262"),
	)
	draw_circle(Vector2(-2.5, -1.0), 1.0, Color("#f7e1a5"))
	draw_circle(Vector2(2.5, -1.0), 1.0, Color("#f7e1a5"))
	draw_line(Vector2(8, 2), Vector2(14, -9), armor_highlight, 2.5)
	draw_line(Vector2(6, 3), Vector2(10, 7), armor_highlight.darkened(0.25), 2.0)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, armor_highlight, 1.5)
	_draw_held_weapon()


func _on_defeated() -> void:
	is_controlled = false
	visible = false
	set_process(false)
	set_physics_process(false)
	if dungeon_level != null:
		dungeon_level.unregister_entity(self)
