class_name DungeonHireling
extends DungeonEntity

const MAX_HEARTS: int = 13
const ATTACK_DAMAGE: int = 3
const HIT_CHANCE: float = 1.0
const SPEED: float = 1.0
const FOLLOW_DISTANCE: int = 1

var is_hired: bool = false
var is_controlled: bool = false
var companion_name: String = "Hired Fighter"
var hit_chance: float = HIT_CHANCE
var inventory: PlayerInventory = PlayerInventory.new()
var _shared_inventory: PlayerInventory = null
var _shared_weapon_copies: Dictionary = {}
var _preserved_weapon_after_shared_break: WeaponData = null


func _init() -> void:
	super._init()
	health = HeartHealth.new(MAX_HEARTS)
	speed = SPEED
	inventory.inventory_changed.connect(_on_inventory_changed)
	inventory.weapon_broken.connect(_on_local_weapon_broken)


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


func set_companion_name(new_name: String) -> void:
	companion_name = new_name.strip_edges()
	if companion_name.is_empty():
		companion_name = "Hired Fighter"
	queue_redraw()


func set_controlled(controlled: bool) -> void:
	is_controlled = controlled
	queue_redraw()


func set_inventory(new_inventory: PlayerInventory) -> void:
	if new_inventory == null:
		return
	if _shared_inventory != null:
		_disconnect_shared_inventory(_shared_inventory)
	_shared_inventory = new_inventory
	_connect_shared_inventory(_shared_inventory)
	_shared_weapon_copies.clear()
	inventory.clear()
	_sync_shared_weapons()
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
	return companion_name


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
		if _shared_inventory != null:
			_shared_inventory.add_weapon(pickup.weapon_data)
		_add_shared_weapon_copy(pickup.weapon_data)
	elif _shared_inventory != null:
		_shared_inventory.add_item(pickup.item_name)
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


func _connect_shared_inventory(shared_inventory: PlayerInventory) -> void:
	if not shared_inventory.inventory_changed.is_connected(_on_shared_inventory_changed):
		shared_inventory.inventory_changed.connect(_on_shared_inventory_changed)
	if not shared_inventory.weapon_wielded.is_connected(_on_shared_weapon_wielded):
		shared_inventory.weapon_wielded.connect(_on_shared_weapon_wielded)
	if not shared_inventory.weapon_unwielded.is_connected(_on_shared_weapon_unwielded):
		shared_inventory.weapon_unwielded.connect(_on_shared_weapon_unwielded)
	if not shared_inventory.weapon_broken.is_connected(_on_shared_weapon_broken):
		shared_inventory.weapon_broken.connect(_on_shared_weapon_broken)


func _disconnect_shared_inventory(shared_inventory: PlayerInventory) -> void:
	if shared_inventory.inventory_changed.is_connected(_on_shared_inventory_changed):
		shared_inventory.inventory_changed.disconnect(_on_shared_inventory_changed)
	if shared_inventory.weapon_wielded.is_connected(_on_shared_weapon_wielded):
		shared_inventory.weapon_wielded.disconnect(_on_shared_weapon_wielded)
	if shared_inventory.weapon_unwielded.is_connected(_on_shared_weapon_unwielded):
		shared_inventory.weapon_unwielded.disconnect(_on_shared_weapon_unwielded)
	if shared_inventory.weapon_broken.is_connected(_on_shared_weapon_broken):
		shared_inventory.weapon_broken.disconnect(_on_shared_weapon_broken)


func _on_shared_inventory_changed() -> void:
	_sync_shared_weapons()
	queue_redraw()


func _on_shared_weapon_wielded(shared_weapon: WeaponData) -> void:
	_sync_shared_weapons()


func _on_shared_weapon_unwielded(shared_weapon: WeaponData) -> void:
	if shared_weapon == null or shared_weapon.is_broken():
		return
	_preserved_weapon_after_shared_break = null
	var local_weapon: WeaponData = _get_local_weapon(shared_weapon)
	if local_weapon != null and inventory.is_weapon_wielded(local_weapon):
		inventory.unwield_weapon(local_weapon)


func _on_shared_weapon_broken(shared_weapon: WeaponData) -> void:
	var local_weapon: WeaponData = _get_local_weapon(shared_weapon)
	if local_weapon != null and inventory.is_weapon_wielded(local_weapon):
		_preserved_weapon_after_shared_break = local_weapon


func _on_local_weapon_broken(broken_weapon: WeaponData) -> void:
	for shared_weapon: WeaponData in _shared_weapon_copies:
		if _shared_weapon_copies[shared_weapon] == broken_weapon:
			_shared_weapon_copies.erase(shared_weapon)
			return


func _sync_shared_weapons() -> void:
	if _shared_inventory == null:
		return

	for shared_weapon: WeaponData in _shared_inventory.get_weapons():
		if not _shared_weapon_copies.has(shared_weapon):
			_add_shared_weapon_copy(shared_weapon)

	var shared_equipped_weapon: WeaponData = _shared_inventory.get_equipped_weapon()
	if shared_equipped_weapon != null:
		var local_weapon: WeaponData = _get_local_weapon(shared_equipped_weapon)
		if local_weapon != null and not inventory.is_weapon_wielded(local_weapon):
			inventory.wield_weapon(local_weapon)
		_preserved_weapon_after_shared_break = null
		return

	if (
		_preserved_weapon_after_shared_break == null
		and inventory.get_equipped_weapon() != null
	):
		inventory.unwield_weapon(inventory.get_equipped_weapon())


func _add_shared_weapon_copy(shared_weapon: WeaponData) -> void:
	if shared_weapon == null or _shared_weapon_copies.has(shared_weapon):
		return
	var local_weapon: WeaponData = shared_weapon.duplicate_with_durability()
	_shared_weapon_copies[shared_weapon] = local_weapon
	inventory.add_weapon(local_weapon)


func _get_local_weapon(shared_weapon: WeaponData) -> WeaponData:
	if shared_weapon == null:
		return null
	var weapon_value: Variant = _shared_weapon_copies.get(shared_weapon, null)
	if weapon_value is WeaponData:
		return weapon_value as WeaponData
	return null


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
