class_name DungeonLevel
extends Node2D

signal dungeon_generated(start_cell: Vector2i, exit_cell: Vector2i)
signal item_collected(item_name: String, cell: Vector2i)
signal combat_event(message: String)

const GRID_WIDTH: int = 25
const GRID_HEIGHT: int = 17
const TILE_SIZE: int = 32
const WALL: int = 0
const FLOOR: int = 1
const ITEM_NAMES: Array[String] = ["Amber Potion", "Ancient Coin", "Crystal Shard"]
const ITEM_COUNT: int = 3
const WEAPON_NAMES: Array[String] = ["Rusty Sword", "Bone Axe"]
const WEAPON_DAMAGE: Array[int] = [2, 3]

var tiles: Array = []
var start_cell: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO
var pickups: Array[ItemPickup] = []
var entities: Array[DungeonEntity] = []
var enemies: Array[DungeonEnemy] = []
var turn_scheduler: TurnScheduler = null

var _player_action_in_progress: bool = false
var _enemy_action_queue: Array[DungeonEnemy] = []
var _active_enemy: DungeonEnemy = null

var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _enter_tree() -> void:
	generate()


func _ready() -> void:
	turn_scheduler = TurnScheduler.new()
	for child: Node in get_children():
		var entity: DungeonEntity = child as DungeonEntity
		if entity != null:
			register_entity(entity)
	_spawn_enemies()


func generate() -> void:
	_clear_enemies()
	_random.randomize()
	tiles.clear()

	for y in range(GRID_HEIGHT):
		var row: Array[int] = []
		for x in range(GRID_WIDTH):
			row.append(WALL)
		tiles.append(row)

	var rooms: Array[Rect2i] = []
	for room_index in range(8):
		var room_width: int = _random.randi_range(3, 6)
		var room_height: int = _random.randi_range(3, 5)
		var room_x: int = _random.randi_range(1, GRID_WIDTH - room_width - 1)
		var room_y: int = _random.randi_range(1, GRID_HEIGHT - room_height - 1)
		var room: Rect2i = Rect2i(room_x, room_y, room_width, room_height)
		rooms.append(room)
		_carve_room(room)

		if room_index > 0:
			var previous_center: Vector2i = rooms[room_index - 1].get_center()
			var current_center: Vector2i = room.get_center()
			_carve_corridor(previous_center, current_center)

	start_cell = rooms[0].get_center()
	exit_cell = rooms[rooms.size() - 1].get_center()
	_spawn_items()
	queue_redraw()
	dungeon_generated.emit(start_cell, exit_cell)
	if is_node_ready():
		_spawn_enemies()


func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_WIDTH or cell.y < 0 or cell.y >= GRID_HEIGHT:
		return false
	return tiles[cell.y][cell.x] == FLOOR


func can_stand_at(world_position: Vector2) -> bool:
	const PLAYER_RADIUS: float = 9.0
	var corners: Array[Vector2] = [
		world_position + Vector2(-PLAYER_RADIUS, -PLAYER_RADIUS),
		world_position + Vector2(PLAYER_RADIUS, -PLAYER_RADIUS),
		world_position + Vector2(-PLAYER_RADIUS, PLAYER_RADIUS),
		world_position + Vector2(PLAYER_RADIUS, PLAYER_RADIUS),
	]
	for corner: Vector2 in corners:
		if not is_walkable(world_to_cell(corner)):
			return false
	return true


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * TILE_SIZE,
		(float(cell.y) + 0.5) * TILE_SIZE
	)


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / TILE_SIZE),
		floori(world_position.y / TILE_SIZE)
	)


func get_start_cell() -> Vector2i:
	return start_cell


func get_exit_cell() -> Vector2i:
	return exit_cell


func register_entity(entity: DungeonEntity) -> void:
	if entity == null or entities.has(entity):
		return

	entities.append(entity)
	if turn_scheduler != null:
		turn_scheduler.add_entity(entity)
	if not entity.action_finished.is_connected(_on_entity_action_finished):
		entity.action_finished.connect(_on_entity_action_finished)
	if not entity.defeated.is_connected(_on_entity_defeated):
		entity.defeated.connect(_on_entity_defeated)


func unregister_entity(entity: DungeonEntity) -> void:
	if entity == null:
		return

	entities.erase(entity)
	if turn_scheduler != null:
		turn_scheduler.remove_entity(entity)
	if entity is DungeonEnemy:
		enemies.erase(entity as DungeonEnemy)


func get_entity_at(cell: Vector2i) -> DungeonEntity:
	for index: int in range(entities.size() - 1, -1, -1):
		var entity: DungeonEntity = entities[index]
		if not is_instance_valid(entity):
			entities.remove_at(index)
			continue
		if entity.health.is_depleted():
			continue
		if entity.current_cell == cell:
			return entity
	return null


func get_player() -> DungeonPlayer:
	for entity: DungeonEntity in entities:
		if entity is DungeonPlayer:
			return entity as DungeonPlayer
	return get_node_or_null("Player") as DungeonPlayer


func begin_player_action(player: DungeonEntity) -> bool:
	if player == null or not player.is_player_entity():
		return false
	if _player_action_in_progress or _active_enemy != null or not _enemy_action_queue.is_empty():
		return false

	_player_action_in_progress = true
	if turn_scheduler != null and not turn_scheduler.has_entity(player):
		turn_scheduler.add_entity(player)
	return true


func spawn_enemy(enemy: DungeonEnemy, cell: Vector2i) -> DungeonEnemy:
	if enemy == null or not is_walkable(cell):
		return null
	if get_entity_at(cell) != null or _has_pickup_at(cell):
		return null

	enemy.setup(self, cell)
	add_child(enemy)
	enemies.append(enemy)
	return enemy


func spawn_hit_effect(cell: Vector2i, damage_hearts: int, effect_color: Color) -> void:
	var effect: HitEffect = HitEffect.new()
	effect.setup(damage_hearts, effect_color)
	effect.position = cell_to_world(cell)
	add_child(effect)


func report_attack(attacker: DungeonEntity, target: DungeonEntity, hit: bool, damage_hearts: int) -> void:
	if attacker == null or target == null:
		return

	var message: String
	if hit and damage_hearts > 0:
		message = "%s hits %s for %d heart%s" % [
			attacker.get_display_name(),
			target.get_display_name(),
			damage_hearts,
			"" if damage_hearts == 1 else "s",
		]
		if target.health.is_depleted():
			message += " and defeats them"
	else:
		message = "%s misses %s" % [attacker.get_display_name(), target.get_display_name()]
	combat_event.emit(message)


func spawn_pickup(item_name: String, cell: Vector2i) -> ItemPickup:
	return _spawn_pickup(item_name, cell)


func spawn_weapon(weapon: WeaponData, cell: Vector2i) -> ItemPickup:
	if weapon == null:
		return null
	return _spawn_pickup(weapon.weapon_name, cell, weapon)


func _spawn_pickup(item_name: String, cell: Vector2i, weapon: WeaponData = null) -> ItemPickup:
	if not is_walkable(cell):
		return null

	var pickup: ItemPickup = ItemPickup.new()
	pickup.setup(item_name, cell, weapon)
	add_child(pickup)
	pickups.append(pickup)
	return pickup


func collect_pickup_at(cell: Vector2i) -> ItemPickup:
	for index: int in range(pickups.size() - 1, -1, -1):
		var pickup: ItemPickup = pickups[index]
		if not is_instance_valid(pickup):
			pickups.remove_at(index)
			continue
		if pickup.cell != cell:
			continue

		var item_name: String = pickup.item_name
		pickups.remove_at(index)
		pickup.queue_free()
		item_collected.emit(item_name, cell)
		return pickup
	return null


func collect_item_at(cell: Vector2i) -> String:
	var pickup: ItemPickup = collect_pickup_at(cell)
	if pickup == null:
		return ""
	return pickup.item_name


func clear_pickups() -> void:
	for pickup: ItemPickup in pickups:
		if is_instance_valid(pickup):
			pickup.queue_free()
	pickups.clear()


func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			tiles[y][x] = FLOOR


func _carve_corridor(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var horizontal_first: bool = _random.randi_range(0, 1) == 0
	if horizontal_first:
		_carve_horizontal(from_cell.x, to_cell.x, from_cell.y)
		_carve_vertical(from_cell.y, to_cell.y, to_cell.x)
	else:
		_carve_vertical(from_cell.y, to_cell.y, from_cell.x)
		_carve_horizontal(from_cell.x, to_cell.x, to_cell.y)


func _carve_horizontal(from_x: int, to_x: int, y: int) -> void:
	var start_x: int = mini(from_x, to_x)
	var end_x: int = maxi(from_x, to_x)
	for x in range(start_x, end_x + 1):
		tiles[y][x] = FLOOR


func _carve_vertical(from_y: int, to_y: int, x: int) -> void:
	var start_y: int = mini(from_y, to_y)
	var end_y: int = maxi(from_y, to_y)
	for y in range(start_y, end_y + 1):
		tiles[y][x] = FLOOR


func _spawn_items() -> void:
	clear_pickups()

	var candidate_cells: Array[Vector2i] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell: Vector2i = Vector2i(x, y)
			if is_walkable(cell) and cell != start_cell and cell != exit_cell:
				candidate_cells.append(cell)

	var item_count: int = mini(ITEM_COUNT, candidate_cells.size())
	for item_index in range(item_count):
		var cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_pickup(ITEM_NAMES[item_index % ITEM_NAMES.size()], cell)

	var weapon_count: int = mini(WEAPON_NAMES.size(), candidate_cells.size())
	for weapon_index in range(weapon_count):
		var weapon_cell: Vector2i = _take_random_candidate(candidate_cells)
		var weapon: WeaponData = WeaponData.new(
			WEAPON_NAMES[weapon_index],
			WEAPON_DAMAGE[weapon_index],
		)
		spawn_weapon(weapon, weapon_cell)


func _spawn_enemies() -> void:
	if not enemies.is_empty():
		return

	var candidate_cells: Array[Vector2i] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell: Vector2i = Vector2i(x, y)
			if not is_walkable(cell) or cell == start_cell or cell == exit_cell:
				continue
			if get_entity_at(cell) != null or _has_pickup_at(cell):
				continue
			candidate_cells.append(cell)

	if candidate_cells.is_empty():
		return

	var zombie_cell: Vector2i = _take_random_candidate(candidate_cells)
	spawn_enemy(ZombieEnemy.new(), zombie_cell)
	if not candidate_cells.is_empty():
		var skeleton_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(SkeletonEnemy.new(), skeleton_cell)


func _clear_enemies() -> void:
	_enemy_action_queue.clear()
	_active_enemy = null
	for enemy: DungeonEnemy in enemies.duplicate():
		if is_instance_valid(enemy):
			unregister_entity(enemy)
			enemy.queue_free()
	enemies.clear()


func _has_pickup_at(cell: Vector2i) -> bool:
	for pickup: ItemPickup in pickups:
		if is_instance_valid(pickup) and pickup.cell == cell:
			return true
	return false


func _on_entity_action_finished(entity: DungeonEntity) -> void:
	if entity == get_player() and _player_action_in_progress:
		_player_action_in_progress = false
		if turn_scheduler == null:
			return
		var due_entities: Array[DungeonEntity] = turn_scheduler.advance_after_action(entity)
		_enemy_action_queue.clear()
		for due_entity: DungeonEntity in due_entities:
			if due_entity is DungeonEnemy:
				_enemy_action_queue.append(due_entity as DungeonEnemy)
		_run_next_enemy_action()
		return

	if entity == _active_enemy:
		_active_enemy = null
		_run_next_enemy_action()


func _run_next_enemy_action() -> void:
	if _active_enemy != null:
		return

	while not _enemy_action_queue.is_empty():
		var enemy: DungeonEnemy = _enemy_action_queue.pop_front()
		if not is_instance_valid(enemy) or enemy.health.is_depleted() or not entities.has(enemy):
			continue
		_active_enemy = enemy
		if enemy.take_turn():
			return
		_active_enemy = null


func _on_entity_defeated(entity: DungeonEntity) -> void:
	if entity == get_player():
		_enemy_action_queue.clear()
		_active_enemy = null
	elif entity is DungeonEnemy:
		unregister_entity(entity)


func _take_random_candidate(candidate_cells: Array[Vector2i]) -> Vector2i:
	var candidate_index: int = _random.randi_range(0, candidate_cells.size() - 1)
	return candidate_cells.pop_at(candidate_index)


func _draw() -> void:
	var map_size: Vector2 = Vector2(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#0b0e15"))

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var tile_rect: Rect2 = Rect2(
				Vector2(x * TILE_SIZE, y * TILE_SIZE),
				Vector2(TILE_SIZE, TILE_SIZE)
			)
			var is_floor: bool = tiles.size() == GRID_HEIGHT and tiles[y][x] == FLOOR
			if is_floor:
				draw_rect(tile_rect, Color("#252b39"))
				draw_rect(tile_rect.grow(-1.0), Color("#303849"))
			else:
				draw_rect(tile_rect.grow(-1.0), Color("#111621"))


	_draw_marker(start_cell, Color("#4bc6a7"), false)
	_draw_marker(exit_cell, Color("#d6a85f"), true)


func _draw_marker(cell: Vector2i, color: Color, is_exit: bool) -> void:
	var marker_center: Vector2 = cell_to_world(cell)
	if is_exit:
		var points: PackedVector2Array = PackedVector2Array([
			marker_center + Vector2(0, -9),
			marker_center + Vector2(9, 0),
			marker_center + Vector2(0, 9),
			marker_center + Vector2(-9, 0),
		])
		draw_colored_polygon(points, color.darkened(0.35))
		draw_polyline(points, color, 2.0)
	else:
		draw_circle(marker_center, 8.0, color.darkened(0.35))
		draw_arc(marker_center, 8.0, 0.0, TAU, 20, color, 2.0)
