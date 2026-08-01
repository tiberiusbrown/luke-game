class_name DungeonLevel
extends Node2D

signal dungeon_generated(start_cell: Vector2i, exit_cell: Vector2i)
signal item_collected(item_name: String, cell: Vector2i)
signal combat_event(message: String)
signal vendor_interaction_requested(vendor: DungeonVendor)
signal companion_event(message: String)
signal player_control_changed(previous_player: DungeonEntity, current_player: DungeonEntity)
signal game_over

const GRID_WIDTH: int = 60
const GRID_HEIGHT: int = 42
const TILE_SIZE: int = 32
const LIGHT_DIAMETER: int = 11
const LIGHT_RADIUS: int = 5
const ROOM_COUNT: int = 24
const WALL: int = 0
const FLOOR: int = 1
const ITEM_NAMES: Array[String] = ["Amber Potion", "Ancient Coin", "Crystal Shard"]
const ITEM_COUNT: int = 3
const ANCIENT_COIN_COUNT: int = 24
const HIRELING_COST: int = 5
const WEAPON_DEFINITIONS: Array[Dictionary] = [
	{"name": "Rusty Sword", "damage": 2},
	{"name": "Bone Axe", "damage": 3},
	{"name": "Iron Mace", "damage": 2},
	{"name": "Crystal Spear", "damage": 3},
	{"name": "Shadow Dagger", "damage": 2},
	{"name": "Thunder Hammer", "damage": 3},
]
const VENDOR_ROOM_INDEX: int = 1

var tiles: Array = []
var start_cell: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO
var vendor_room: Rect2i = Rect2i()
var vendor_cell: Vector2i = Vector2i.ZERO
var vendor: DungeonVendor = null
var hireling_cell: Vector2i = Vector2i.ZERO
var hireling: DungeonHireling = null
var has_hired_hireling: bool = false
var is_hireling_dead: bool = false
var pickups: Array[ItemPickup] = []
var entities: Array[DungeonEntity] = []
var enemies: Array[DungeonEnemy] = []
var turn_scheduler: TurnScheduler = null
var visible_cells: Dictionary = {}
var known_cells: Dictionary = {}
var active_player: DungeonEntity = null
var is_game_over: bool = false

var _player_action_in_progress: bool = false
var _non_player_action_queue: Array[DungeonEntity] = []
var _active_non_player: DungeonEntity = null

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _field_of_view: DungeonFieldOfView = DungeonFieldOfView.new(GRID_WIDTH, GRID_HEIGHT)


func _enter_tree() -> void:
	generate()


func _ready() -> void:
	turn_scheduler = TurnScheduler.new()
	for child: Node in get_children():
		var entity: DungeonEntity = child as DungeonEntity
		if entity != null:
			register_entity(entity)
	var scene_player: DungeonPlayer = get_node_or_null("Player") as DungeonPlayer
	if scene_player != null and active_player == null:
		set_initial_player(scene_player)
	_spawn_enemies()
	_refresh_visibility()


func generate() -> void:
	_clear_enemies()
	_clear_hireling()
	has_hired_hireling = false
	is_hireling_dead = false
	is_game_over = false
	active_player = null
	_random.randomize()
	tiles.clear()
	visible_cells.clear()
	known_cells.clear()

	for y in range(GRID_HEIGHT):
		var row: Array[int] = []
		for x in range(GRID_WIDTH):
			row.append(WALL)
		tiles.append(row)

	var rooms: Array[Rect2i] = []
	for room_index in range(ROOM_COUNT):
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
	vendor_room = rooms[mini(VENDOR_ROOM_INDEX, rooms.size() - 1)]
	vendor_cell = _find_vendor_cell(vendor_room)
	_spawn_vendor()
	_spawn_hireling()
	_spawn_items()
	queue_redraw()
	dungeon_generated.emit(start_cell, exit_cell)
	if is_node_ready():
		_spawn_enemies()
		_refresh_visibility()


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


func get_vendor() -> DungeonVendor:
	return vendor


func get_vendor_room() -> Rect2i:
	return vendor_room


func get_hireling() -> DungeonHireling:
	return hireling


func get_hireling_cell() -> Vector2i:
	return hireling_cell


func is_hireling_hired() -> bool:
	return has_hired_hireling


func get_hireling_notification() -> String:
	var player: DungeonEntity = get_player()
	if (
		player == null
		or is_game_over
		or hireling == null
		or not is_instance_valid(hireling)
		or is_hireling_dead
		or player == hireling
		or not _are_adjacent(player.current_cell, hireling.current_cell)
	):
		return ""
	if has_hired_hireling:
		return "HIRED FIGHTER\nFIGHTS FOR YOU"
	return "PRESS E TO HIRE FIGHTER\n5 ANCIENT COINS"


func get_vendor_at(cell: Vector2i) -> DungeonVendor:
	if vendor != null and is_instance_valid(vendor) and vendor.cell == cell:
		return vendor
	return null


func interact_with_vendor(player_cell: Vector2i) -> bool:
	if vendor == null or not is_instance_valid(vendor):
		return false
	if not _are_adjacent(player_cell, vendor.cell):
		return false

	vendor_interaction_requested.emit(vendor)
	return true


func interact_with_hireling(player_cell: Vector2i, player_inventory: PlayerInventory) -> bool:
	if hireling == null or not is_instance_valid(hireling):
		return false
	if not _are_adjacent(player_cell, hireling.current_cell):
		return false
	if is_hireling_dead:
		return true
	if has_hired_hireling:
		companion_event.emit("The hired fighter is ready to fight")
		return true
	if player_inventory == null or player_inventory.get_item_count("Ancient Coin") < HIRELING_COST:
		companion_event.emit("The fighter needs %d Ancient Coins" % HIRELING_COST)
		return true

	for _coin_index: int in range(HIRELING_COST):
		if not player_inventory.remove_item("Ancient Coin"):
			return true

	has_hired_hireling = true
	hireling.hire()
	companion_event.emit("You hire the fighter for %d Ancient Coins" % HIRELING_COST)
	return true


func refresh_visibility() -> void:
	_refresh_visibility()


func is_cell_visible(cell: Vector2i) -> bool:
	return visible_cells.has(cell)


func is_cell_known(cell: Vector2i) -> bool:
	return known_cells.has(cell)


func register_entity(entity: DungeonEntity) -> void:
	if entity == null:
		return

	if not entities.has(entity):
		entities.append(entity)
	if turn_scheduler != null and not turn_scheduler.has_entity(entity):
		turn_scheduler.add_entity(entity)
	if not entity.action_finished.is_connected(_on_entity_action_finished):
		entity.action_finished.connect(_on_entity_action_finished)
	if not entity.defeated.is_connected(_on_entity_defeated):
		entity.defeated.connect(_on_entity_defeated)
	if not entity.movement_finished.is_connected(_on_entity_movement_finished):
		entity.movement_finished.connect(_on_entity_movement_finished)
	if entity is DungeonPlayer and active_player == null:
		set_initial_player(entity as DungeonPlayer)
	_refresh_visibility()


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


func set_initial_player(new_player: DungeonPlayer) -> void:
	if active_player != null or new_player == null or new_player.health.is_depleted():
		return
	_set_active_player(new_player)


func get_player() -> DungeonEntity:
	if active_player == null or not is_instance_valid(active_player):
		return null
	if active_player.health == null or active_player.health.is_depleted():
		return null
	return active_player


func begin_player_action(player: DungeonEntity) -> bool:
	if is_game_over or player == null or player != active_player or not player.is_player_entity():
		return false
	if _player_action_in_progress:
		return false

	_player_action_in_progress = true
	_speed_up_non_player_animations()
	if turn_scheduler != null and not turn_scheduler.has_entity(player):
		turn_scheduler.add_entity(player)
	return true


func spawn_enemy(enemy: DungeonEnemy, cell: Vector2i) -> DungeonEnemy:
	if enemy == null or not is_walkable(cell):
		return null
	if get_entity_at(cell) != null or _has_pickup_at(cell) or get_vendor_at(cell) != null:
		return null

	enemy.setup(self, cell)
	add_child(enemy)
	enemies.append(enemy)
	_refresh_visibility()
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
	_refresh_visibility()
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
			if (
				is_walkable(cell)
				and cell != start_cell
				and cell != exit_cell
				and cell != hireling_cell
				and not vendor_room.has_point(cell)
			):
				candidate_cells.append(cell)

	var item_count: int = mini(ITEM_COUNT, candidate_cells.size())
	for item_index in range(item_count):
		var cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_pickup(ITEM_NAMES[item_index % ITEM_NAMES.size()], cell)

	var coin_count: int = mini(ANCIENT_COIN_COUNT, candidate_cells.size())
	for _coin_index in range(coin_count):
		var coin_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_pickup("Ancient Coin", coin_cell)

	var weapon_count: int = mini(WEAPON_DEFINITIONS.size(), candidate_cells.size())
	for weapon_index in range(weapon_count):
		var weapon_cell: Vector2i = _take_random_candidate(candidate_cells)
		var weapon_definition: Dictionary = WEAPON_DEFINITIONS[weapon_index]
		var weapon: WeaponData = WeaponData.new(
			str(weapon_definition["name"]),
			int(weapon_definition["damage"]),
		)
		spawn_weapon(weapon, weapon_cell)


func _spawn_enemies() -> void:
	if not enemies.is_empty():
		return

	var candidate_cells: Array[Vector2i] = []
	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var cell: Vector2i = Vector2i(x, y)
			if (
				not is_walkable(cell)
				or cell == start_cell
				or cell == exit_cell
				or cell == hireling_cell
				or vendor_room.has_point(cell)
			):
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
	if not candidate_cells.is_empty():
		var vampire_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(VampireEnemy.new(), vampire_cell)
	if not candidate_cells.is_empty():
		var spider_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(SpiderEnemy.new(), spider_cell)
	if not candidate_cells.is_empty():
		var ghost_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(GhostEnemy.new(), ghost_cell)


func _clear_enemies() -> void:
	_non_player_action_queue.clear()
	_active_non_player = null
	for enemy: DungeonEnemy in enemies.duplicate():
		if is_instance_valid(enemy):
			unregister_entity(enemy)
			enemy.queue_free()
	enemies.clear()


func _clear_hireling() -> void:
	if hireling == null or not is_instance_valid(hireling):
		hireling = null
		return
	unregister_entity(hireling)
	hireling.queue_free()
	hireling = null


func _has_pickup_at(cell: Vector2i) -> bool:
	for pickup: ItemPickup in pickups:
		if is_instance_valid(pickup) and pickup.cell == cell:
			return true
	return false


func _spawn_vendor() -> void:
	if vendor != null and is_instance_valid(vendor):
		vendor.queue_free()

	vendor = DungeonVendor.new()
	vendor.setup(self, vendor_cell)
	add_child(vendor)


func _spawn_hireling() -> void:
	var candidate_cells: Array[Vector2i] = []
	for y: int in range(GRID_HEIGHT):
		for x: int in range(GRID_WIDTH):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and cell != start_cell
				and cell != exit_cell
				and not vendor_room.has_point(cell)
			):
				candidate_cells.append(cell)

	if candidate_cells.is_empty():
		return

	hireling_cell = _take_random_candidate(candidate_cells)
	hireling = DungeonHireling.new()
	hireling.setup(self, hireling_cell)
	add_child(hireling)


func _find_vendor_cell(room: Rect2i) -> Vector2i:
	var preferred_cell: Vector2i = room.get_center()
	if is_walkable(preferred_cell) and preferred_cell != start_cell and preferred_cell != exit_cell:
		return preferred_cell

	for y: int in range(room.position.y, room.end.y):
		for x: int in range(room.position.x, room.end.x):
			var candidate_cell: Vector2i = Vector2i(x, y)
			if is_walkable(candidate_cell) and candidate_cell != start_cell and candidate_cell != exit_cell:
				return candidate_cell
	return preferred_cell


func _are_adjacent(first_cell: Vector2i, second_cell: Vector2i) -> bool:
	var difference: Vector2i = second_cell - first_cell
	return abs(difference.x) + abs(difference.y) == 1


func _on_entity_action_finished(entity: DungeonEntity) -> void:
	if entity == get_player() and _player_action_in_progress:
		_player_action_in_progress = false
		if turn_scheduler == null:
			return
		var due_entities: Array[DungeonEntity] = turn_scheduler.advance_after_action(entity)
		for due_entity: DungeonEntity in due_entities:
			if due_entity != get_player() and (due_entity is DungeonEnemy or due_entity is DungeonHireling):
				_non_player_action_queue.append(due_entity)
		_run_next_non_player_action()
		return

	if entity == _active_non_player:
		_active_non_player = null
		_run_next_non_player_action()


func _on_entity_movement_finished(_entity: DungeonEntity, _cell: Vector2i) -> void:
	_refresh_visibility()


func _run_next_non_player_action() -> void:
	if _active_non_player != null:
		return

	while not _non_player_action_queue.is_empty():
		var entity: DungeonEntity = _non_player_action_queue.pop_front()
		if (
			not is_instance_valid(entity)
			or entity.health.is_depleted()
			or not entities.has(entity)
			or entity == get_player()
			or entity.is_player_entity()
		):
			continue

		_active_non_player = entity
		var action_started: bool = false
		if entity is DungeonEnemy:
			action_started = (entity as DungeonEnemy).take_turn()
		elif entity is DungeonHireling:
			action_started = (entity as DungeonHireling).take_turn()
		if action_started:
			if _player_action_in_progress:
				entity.speed_up_action_animation()
			return
		_active_non_player = null


func _speed_up_non_player_animations() -> void:
	for entity: DungeonEntity in entities:
		if not is_instance_valid(entity) or entity.is_player_entity():
			continue
		entity.speed_up_action_animation()


func _on_entity_defeated(entity: DungeonEntity) -> void:
	if entity == active_player:
		_player_action_in_progress = false
		if entity == hireling:
			is_hireling_dead = true
			if has_hired_hireling:
				companion_event.emit("Your hired fighter has fallen")
		if has_hired_hireling and not is_hireling_dead and _is_hireling_alive():
			var defeated_player: DungeonEntity = active_player
			unregister_entity(defeated_player)
			_set_active_player(hireling)
			companion_event.emit("You take control of the hired fighter")
			_refresh_visibility()
			return
		_end_game()
		return

	if entity == hireling:
		is_hireling_dead = true
		if has_hired_hireling:
			companion_event.emit("Your hired fighter has fallen")
		unregister_entity(entity)
		return

	if entity is DungeonEnemy:
		unregister_entity(entity)


func _set_active_player(new_player: DungeonEntity) -> void:
	if new_player == null or not is_instance_valid(new_player) or new_player.health.is_depleted():
		return

	var previous_player: DungeonEntity = active_player
	if previous_player == new_player:
		return
	if previous_player is DungeonPlayer:
		(previous_player as DungeonPlayer).set_controlled(false)
	elif previous_player is DungeonHireling:
		(previous_player as DungeonHireling).set_controlled(false)

	active_player = new_player
	if new_player is DungeonPlayer:
		(new_player as DungeonPlayer).set_controlled(true)
	elif new_player is DungeonHireling:
		(new_player as DungeonHireling).set_controlled(true)
	if turn_scheduler != null and not turn_scheduler.has_entity(new_player):
		turn_scheduler.add_entity(new_player)
	player_control_changed.emit(previous_player, new_player)


func _is_hireling_alive() -> bool:
	return hireling != null and is_instance_valid(hireling) and not hireling.health.is_depleted()


func _end_game() -> void:
	if is_game_over:
		return
	is_game_over = true
	_player_action_in_progress = false
	_non_player_action_queue.clear()
	_active_non_player = null
	var defeated_player: DungeonEntity = active_player
	active_player = null
	if defeated_player is DungeonPlayer:
		(defeated_player as DungeonPlayer).set_controlled(false)
	elif defeated_player is DungeonHireling:
		(defeated_player as DungeonHireling).set_controlled(false)
	if defeated_player != null:
		unregister_entity(defeated_player)
	game_over.emit()
	_refresh_visibility()


func _take_random_candidate(candidate_cells: Array[Vector2i]) -> Vector2i:
	var candidate_index: int = _random.randi_range(0, candidate_cells.size() - 1)
	return candidate_cells.pop_at(candidate_index)


func _refresh_visibility() -> void:
	visible_cells.clear()
	var player: DungeonEntity = get_player()
	if player != null and is_instance_valid(player):
		var lit_cells: Array[Vector2i] = _field_of_view.compute(
			player.current_cell,
			LIGHT_RADIUS,
			Callable(self, "_is_opaque_for_field_of_view"),
		)
		for cell: Vector2i in lit_cells:
			visible_cells[cell] = true
			known_cells[cell] = true

	for entity: DungeonEntity in entities:
		if not is_instance_valid(entity):
			continue
		if entity.health == null or entity.health.is_depleted():
			entity.visible = false
			continue
		entity.visible = entity.is_player_entity() or is_cell_visible(entity.current_cell)

	for pickup: ItemPickup in pickups:
		if not is_instance_valid(pickup):
			continue
		pickup.set_explored_state(is_cell_visible(pickup.cell), is_cell_known(pickup.cell))

	if vendor != null and is_instance_valid(vendor):
		vendor.set_explored_state(is_cell_visible(vendor.cell), is_cell_known(vendor.cell))

	queue_redraw()


func _is_opaque_for_field_of_view(cell: Vector2i) -> bool:
	return not is_walkable(cell)


func _draw() -> void:
	var map_size: Vector2 = Vector2(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#0b0e15"))

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var tile_rect: Rect2 = Rect2(
				Vector2(x * TILE_SIZE, y * TILE_SIZE),
				Vector2(TILE_SIZE, TILE_SIZE)
			)
			var cell: Vector2i = Vector2i(x, y)
			if not is_cell_known(cell):
				draw_rect(tile_rect, Color("#080a10"))
				continue

			var is_floor: bool = tiles.size() == GRID_HEIGHT and tiles[y][x] == FLOOR
			var is_lit: bool = is_cell_visible(cell)
			if is_floor and is_lit:
				draw_rect(tile_rect, Color("#252b39"))
				draw_rect(tile_rect.grow(-1.0), Color("#303849"))
			elif is_floor:
				draw_rect(tile_rect, Color("#141a27"))
				draw_rect(tile_rect.grow(-1.0), Color("#1b2231"))
			elif is_lit:
				draw_rect(tile_rect.grow(-1.0), Color("#111621"))
			else:
				draw_rect(tile_rect.grow(-1.0), Color("#0b0f18"))


	if is_cell_known(start_cell):
		_draw_marker(start_cell, Color("#4bc6a7"), false)
	if is_cell_known(exit_cell):
		_draw_marker(exit_cell, Color("#d6a85f"), true)
	if vendor_room.size != Vector2i.ZERO and is_cell_known(vendor_cell):
		var room_rect: Rect2 = Rect2(
			Vector2(vendor_room.position * TILE_SIZE),
			Vector2(vendor_room.size * TILE_SIZE),
		)
		draw_rect(room_rect.grow(-2.0), Color(0.84, 0.66, 0.37, 0.38), false, 2.0)


func _draw_marker(cell: Vector2i, color: Color, is_exit: bool) -> void:
	var marker_center: Vector2 = cell_to_world(cell)
	var marker_color: Color = color if is_cell_visible(cell) else color.darkened(0.55)
	if is_exit:
		var points: PackedVector2Array = PackedVector2Array([
			marker_center + Vector2(0, -9),
			marker_center + Vector2(9, 0),
			marker_center + Vector2(0, 9),
			marker_center + Vector2(-9, 0),
		])
		draw_colored_polygon(points, marker_color.darkened(0.35))
		draw_polyline(points, marker_color, 2.0)
	else:
		draw_circle(marker_center, 8.0, marker_color.darkened(0.35))
		draw_arc(marker_center, 8.0, 0.0, TAU, 20, marker_color, 2.0)
