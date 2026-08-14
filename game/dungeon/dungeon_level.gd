class_name DungeonLevel
extends Node2D

enum MapSide { LEFT, RIGHT, TOP, BOTTOM }
enum Difficulty { EASY, NORMAL, HARD }

signal dungeon_generated(start_cell: Vector2i, exit_cell: Vector2i)
signal item_collected(item_name: String, cell: Vector2i)
signal combat_event(message: String)
signal vendor_interaction_requested(vendor: DungeonVendor)
signal shop_interaction_requested(shop: DungeonShop)
signal npc_interaction_requested(npc: DungeonCastleNpc)
signal quest_board_interaction_requested(board: DungeonQuestBoard)
signal companion_event(message: String)
signal prison_event(message: String)
signal castle_boundary_blocked
signal player_control_changed(previous_player: DungeonEntity, current_player: DungeonEntity)
signal game_over
signal trial_completed

const GRID_WIDTH: int = 96
const GRID_HEIGHT: int = 64
const TILE_SIZE: int = 32
const LIGHT_DIAMETER: int = 11
const LIGHT_RADIUS: int = 5
const ROOM_COUNT: int = 48
const WALL: int = 0
const FLOOR: int = 1
const ITEM_NAMES: Array[String] = ["Ancient Coin", "Crystal Shard"]
const ITEM_COUNT: int = 2
const HEALING_ITEM_NAMES: Array[String] = [
	"Amber Potion",
	"Moonleaf Tonic",
	"Sunstone",
	"Crimson Draught",
	"Heartroot Poultice",
]
const ANCIENT_COIN_COUNT: int = 24
const BOOBY_TRAP_COUNT: int = 12
const HIRELING_COST: int = 5
const MONSTER_COUNT: int = 16
const SKULL_ITEM_NAME: String = "Skull"
const TRIAL_GRID_WIDTH: int = 80
const TRIAL_GRID_HEIGHT: int = 54
const TRIAL_ROOM_COUNT: int = 28
const TRIAL_CYCLOPES_COUNT: int = 10
const BOSS_PRISON_KEY: String = "Boss Prison Key"
const BOSS_PRISON_KEY_ITEM_NAME: String = BOSS_PRISON_KEY
const PRISON_ROOM_SIZE: Vector2i = Vector2i(8, 7)
const PRISON_ROOM_MARGIN: int = 2
const CASTLE_SIZE: Vector2i = Vector2i(64, 44)
const CASTLE_KNIGHT_COST: int = 5
const WEAPON_DEFINITIONS: Array[Dictionary] = [
	{"name": "Rusty Sword", "damage": 2},
	{"name": "Bone Axe", "damage": 3},
	{"name": "Iron Mace", "damage": 2},
	{"name": "Crystal Spear", "damage": 3},
	{"name": "Shadow Dagger", "damage": 2},
	{"name": "Thunder Hammer", "damage": 3},
]
const VENDOR_ROOM_INDEX: int = 1
const DEFAULT_DIFFICULTY: Difficulty = Difficulty.NORMAL

var tiles: Array = []
var start_cell: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO
var start_side: int = MapSide.LEFT
var monster_spawn_side: int = MapSide.RIGHT
var monster_spawn_cells: Array[Vector2i] = []
var vendor_room: Rect2i = Rect2i()
var vendor_cell: Vector2i = Vector2i.ZERO
var vendor: DungeonVendor = null
var castle_area: Rect2i = Rect2i()
var above_ground_castle_area: Rect2i = Rect2i()
var castle_entry_stairs_cell: Vector2i = Vector2i.ZERO
var castle_entry_cell: Vector2i = Vector2i.ZERO
var is_castle_entered: bool = false
var castle_npcs: Array[DungeonCastleNpc] = []
var castle_knights: Array[DungeonHireling] = []
var quest_board: DungeonQuestBoard = null
var weapon_shop: DungeonShop = null
var healing_shop: DungeonShop = null
var weapon_shop_cell: Vector2i = Vector2i.ZERO
var healing_shop_cell: Vector2i = Vector2i.ZERO
var hireling_cell: Vector2i = Vector2i.ZERO
var hireling: DungeonHireling = null
var has_hired_hireling: bool = false
var is_hireling_dead: bool = false
var prison_room: Rect2i = Rect2i()
var prison_door_cell: Vector2i = Vector2i.ZERO
var prison_boss_cell: Vector2i = Vector2i.ZERO
var prison_key_cell: Vector2i = Vector2i.ZERO
var prison_boss: CyclopesEnemy = null
var monster_spawner: MonsterSpawner = null
var is_prison_unlocked: bool = false
var pickups: Array[ItemPickup] = []
var booby_traps: Array[BoobyTrap] = []
var entities: Array[DungeonEntity] = []
var enemies: Array[DungeonEnemy] = []
var turn_scheduler: TurnScheduler = null
var visible_cells: Dictionary = {}
var known_cells: Dictionary = {}
var active_player: DungeonEntity = null
var is_game_over: bool = false
var is_impossible_trial: bool = false
var difficulty: Difficulty = DEFAULT_DIFFICULTY
var map_width: int = GRID_WIDTH
var map_height: int = GRID_HEIGHT
var room_count: int = ROOM_COUNT

var _player_action_in_progress: bool = false
var _non_player_action_queue: Array[DungeonEntity] = []
var _active_non_player: DungeonEntity = null

var _random: RandomNumberGenerator = RandomNumberGenerator.new()
var _field_of_view: DungeonFieldOfView = DungeonFieldOfView.new(GRID_WIDTH, GRID_HEIGHT)


func configure_impossible_trial() -> void:
	is_impossible_trial = true
	map_width = TRIAL_GRID_WIDTH
	map_height = TRIAL_GRID_HEIGHT
	room_count = TRIAL_ROOM_COUNT
	_field_of_view = DungeonFieldOfView.new(map_width, map_height)


func set_difficulty(new_difficulty: Difficulty) -> void:
	difficulty = new_difficulty
	if quest_board != null and is_instance_valid(quest_board):
		quest_board.configure_for_difficulty(difficulty)
	_apply_difficulty_to_enemies()
	if not is_node_ready() or is_impossible_trial:
		return
	if difficulty != Difficulty.HARD:
		_clear_monster_spawner()
	else:
		_spawn_monster_spawner()
	_refresh_visibility()


func get_difficulty() -> Difficulty:
	return difficulty


func has_boss() -> bool:
	return difficulty != Difficulty.EASY


func has_monster_spawner() -> bool:
	return monster_spawner != null and is_instance_valid(monster_spawner)


func should_spawn_monster_spawner() -> bool:
	return difficulty == Difficulty.HARD


func get_enemy_damage_modifier() -> int:
	return -1 if difficulty == Difficulty.EASY else 0


func get_difficulty_name() -> String:
	match difficulty:
		Difficulty.EASY:
			return "Easy"
		Difficulty.HARD:
			return "Hard"
		_:
			return "Normal"


func _apply_difficulty_to_enemies() -> void:
	for enemy: DungeonEnemy in enemies:
		if is_instance_valid(enemy):
			enemy.apply_difficulty_damage_modifier(get_enemy_damage_modifier())


func get_map_size() -> Vector2:
	return Vector2(map_width * TILE_SIZE, map_height * TILE_SIZE)


func is_trial() -> bool:
	return is_impossible_trial


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
	if not is_impossible_trial and should_spawn_monster_spawner():
		_spawn_monster_spawner()
	_refresh_visibility()


func generate() -> void:
	_clear_enemies()
	clear_booby_traps()
	_clear_hireling()
	_clear_castle()
	prison_boss = null
	_clear_monster_spawner()
	has_hired_hireling = false
	is_hireling_dead = false
	is_game_over = false
	active_player = null
	is_prison_unlocked = false
	prison_room = Rect2i()
	prison_door_cell = Vector2i.ZERO
	prison_boss_cell = Vector2i.ZERO
	prison_key_cell = Vector2i.ZERO
	_random.randomize()
	tiles.clear()
	visible_cells.clear()
	known_cells.clear()
	monster_spawn_cells.clear()

	for y in range(map_height):
		var row: Array[int] = []
		for x in range(map_width):
			row.append(WALL)
		tiles.append(row)

	start_side = _random.randi_range(MapSide.LEFT, MapSide.BOTTOM)
	monster_spawn_side = _get_opposite_side(start_side)

	var rooms: Array[Rect2i] = []
	var start_room: Rect2i = _create_edge_room(start_side)
	rooms.append(start_room)
	_carve_room(start_room)
	for room_index in range(1, room_count):
		var room: Rect2i
		if room_index == room_count - 1:
			room = _create_edge_room(monster_spawn_side)
		else:
			var room_width: int = _random.randi_range(3, 6)
			var room_height: int = _random.randi_range(3, 5)
			var room_x: int = _random.randi_range(1, map_width - room_width - 1)
			var room_y: int = _random.randi_range(1, map_height - room_height - 1)
			room = Rect2i(room_x, room_y, room_width, room_height)
		rooms.append(room)
		_carve_room(room)

		if room_index > 0:
			var previous_center: Vector2i = rooms[room_index - 1].get_center()
			var current_center: Vector2i = room.get_center()
			_carve_corridor(previous_center, current_center)

	start_cell = _get_edge_cell(start_room, start_side)
	exit_cell = rooms[rooms.size() - 1].get_center()
	if is_impossible_trial:
		castle_area = Rect2i()
		above_ground_castle_area = Rect2i()
		castle_entry_stairs_cell = Vector2i.ZERO
		castle_entry_cell = Vector2i.ZERO
		is_castle_entered = false
		vendor_room = Rect2i()
		vendor_cell = Vector2i.ZERO
		prison_room = Rect2i()
		monster_spawn_cells = _reserve_trial_spawn_cells()
	else:
		castle_area = _create_castle_area(start_room)
		above_ground_castle_area = castle_area
		_carve_castle_area(castle_area)
		castle_entry_stairs_cell = castle_area.position + Vector2i(castle_area.size.x / 2, -1)
		castle_entry_cell = castle_area.position + Vector2i(castle_area.size.x / 2, 1)
		tiles[castle_entry_stairs_cell.y][castle_entry_stairs_cell.x] = FLOOR
		_carve_corridor(start_room.get_center(), castle_entry_stairs_cell)
		_seal_castle_walls(castle_area)
		is_castle_entered = false
		_spawn_castle()
		vendor_room = rooms[mini(VENDOR_ROOM_INDEX, rooms.size() - 1)]
		vendor_cell = _find_vendor_cell(vendor_room)
		_build_prison(rooms)
		monster_spawn_cells = _reserve_monster_spawn_cells()

	if is_impossible_trial:
		vendor_room = Rect2i()
		vendor_cell = Vector2i.ZERO
		hireling_cell = Vector2i.ZERO
	else:
		_spawn_vendor()
		_spawn_hireling()
		_spawn_items()
		_spawn_booby_traps()
	queue_redraw()
	dungeon_generated.emit(start_cell, exit_cell)
	if is_node_ready():
		_spawn_enemies()
		if not is_impossible_trial and should_spawn_monster_spawner():
			_spawn_monster_spawner()
		_refresh_visibility()


func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= map_width or cell.y < 0 or cell.y >= map_height:
		return false
	return tiles[cell.y][cell.x] == FLOOR


func can_player_move_to(from_cell: Vector2i, target_cell: Vector2i) -> bool:
	if not is_walkable(target_cell):
		return false
	if (
		is_impossible_trial
		or not is_castle_entered
		or castle_area.size == Vector2i.ZERO
		or above_ground_castle_area.size == Vector2i.ZERO
	):
		return true
	if (
		above_ground_castle_area.has_point(from_cell)
		and above_ground_castle_area.has_point(target_cell)
	):
		return true
	if not above_ground_castle_area.has_point(from_cell):
		return true
	castle_boundary_blocked.emit()
	return false


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


func get_start_side() -> int:
	return start_side


func get_monster_spawn_side() -> int:
	return monster_spawn_side


func is_map_edge_cell(cell: Vector2i) -> bool:
	return (
		cell.x == 0
		or cell.x == map_width - 1
		or cell.y == 0
		or cell.y == map_height - 1
	)


func is_cell_on_side(cell: Vector2i, side: int) -> bool:
	match side:
		MapSide.LEFT:
			return cell.x < map_width / 2
		MapSide.RIGHT:
			return cell.x >= map_width / 2
		MapSide.TOP:
			return cell.y < map_height / 2
		MapSide.BOTTOM:
			return cell.y >= map_height / 2
	return false


func get_vendor() -> DungeonVendor:
	return vendor


func get_castle_area() -> Rect2i:
	return castle_area


func get_above_ground_castle_area() -> Rect2i:
	return above_ground_castle_area


func get_castle_entry_stairs_cell() -> Vector2i:
	return castle_entry_stairs_cell


func has_entered_castle() -> bool:
	return is_castle_entered


func interact_with_castle_entry(player_cell: Vector2i) -> bool:
	if is_impossible_trial or castle_entry_stairs_cell == Vector2i.ZERO:
		return false
	if player_cell != castle_entry_stairs_cell and player_cell != castle_entry_cell:
		return false

	var player: DungeonEntity = get_player()
	if player == null or not is_instance_valid(player):
		return false

	if is_castle_entered:
		if player_cell != castle_entry_cell:
			return false
		is_castle_entered = false
		player.current_cell = castle_entry_stairs_cell
		player.position = cell_to_world(castle_entry_stairs_cell)
		_refresh_visibility()
		companion_event.emit("You descend the stairs back into the dungeon.")
		return true

	is_castle_entered = true
	player.current_cell = castle_entry_cell
	player.position = cell_to_world(castle_entry_cell)
	_refresh_visibility()
	companion_event.emit("You climb the ancient stairs into the high castle. Return to these stairs to leave.")
	return true


func is_inside_above_ground_castle(cell: Vector2i) -> bool:
	return above_ground_castle_area.size != Vector2i.ZERO and above_ground_castle_area.has_point(cell)


func is_safe_area_cell(cell: Vector2i) -> bool:
	return castle_area.size != Vector2i.ZERO and castle_area.has_point(cell)


func get_weapon_shop() -> DungeonShop:
	return weapon_shop


func get_healing_shop() -> DungeonShop:
	return healing_shop


func get_shop_at(cell: Vector2i) -> DungeonShop:
	if weapon_shop != null and is_instance_valid(weapon_shop) and weapon_shop.cell == cell:
		return weapon_shop
	if healing_shop != null and is_instance_valid(healing_shop) and healing_shop.cell == cell:
		return healing_shop
	return null


func get_castle_npc_at(cell: Vector2i) -> DungeonCastleNpc:
	for npc: DungeonCastleNpc in castle_npcs:
		if is_instance_valid(npc) and npc.cell == cell:
			return npc
	return null


func get_castle_knight_at(cell: Vector2i) -> DungeonHireling:
	for knight: DungeonHireling in castle_knights:
		if is_instance_valid(knight) and knight.current_cell == cell:
			return knight
	return null


func get_quest_board() -> DungeonQuestBoard:
	return quest_board


func get_vendor_room() -> Rect2i:
	return vendor_room


func get_hireling() -> DungeonHireling:
	return hireling


func get_hireling_cell() -> Vector2i:
	return hireling_cell


func get_prison_room() -> Rect2i:
	return prison_room


func get_prison_door_cell() -> Vector2i:
	return prison_door_cell


func get_prison_boss_cell() -> Vector2i:
	return prison_boss_cell


func get_prison_key_cell() -> Vector2i:
	return prison_key_cell


func get_prison_boss() -> CyclopesEnemy:
	if prison_boss == null or not is_instance_valid(prison_boss):
		return null
	return prison_boss


func get_monster_spawner() -> MonsterSpawner:
	if monster_spawner == null or not is_instance_valid(monster_spawner):
		return null
	return monster_spawner


func is_boss_prison_unlocked() -> bool:
	return is_prison_unlocked


func is_boss_prison_locked() -> bool:
	return not is_prison_unlocked


func is_hireling_hired() -> bool:
	return has_hired_hireling


func has_hired_companion() -> bool:
	return _get_hired_companion() != null


func get_hired_companions() -> Array[DungeonHireling]:
	var companions: Array[DungeonHireling] = []
	if (
		hireling != null
		and is_instance_valid(hireling)
		and hireling.is_hired
		and not hireling.health.is_depleted()
	):
		companions.append(hireling)
	for knight: DungeonHireling in castle_knights:
		if (
			is_instance_valid(knight)
			and knight.is_hired
			and not knight.health.is_depleted()
		):
			companions.append(knight)
	return companions


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


func get_castle_knight_notification() -> String:
	var player: DungeonEntity = get_player()
	if player == null or is_game_over:
		return ""
	for knight: DungeonHireling in castle_knights:
		if (
			is_instance_valid(knight)
			and not knight.is_hired
			and _are_adjacent(player.current_cell, knight.current_cell)
		):
			return "PRESS E TO HIRE %s\n%d ANCIENT COINS" % [
				knight.get_display_name().to_upper(),
				CASTLE_KNIGHT_COST,
			]
	return ""


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


func interact_with_shop(player_cell: Vector2i) -> bool:
	var shop: DungeonShop = null
	for candidate: DungeonShop in [weapon_shop, healing_shop]:
		if candidate != null and is_instance_valid(candidate) and _are_adjacent(player_cell, candidate.cell):
			shop = candidate
			break
	if shop == null:
		return false
	shop_interaction_requested.emit(shop)
	return true


func interact_with_quest_board(player_cell: Vector2i) -> bool:
	if quest_board == null or not is_instance_valid(quest_board):
		return false
	if not _are_adjacent(player_cell, quest_board.cell):
		return false
	quest_board_interaction_requested.emit(quest_board)
	return true


func interact_with_castle_npc(player_cell: Vector2i) -> bool:
	for npc: DungeonCastleNpc in castle_npcs:
		if is_instance_valid(npc) and _are_adjacent(player_cell, npc.cell):
			npc_interaction_requested.emit(npc)
			return true
	return false


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
	hireling.set_inventory(player_inventory)
	hireling.hire()
	companion_event.emit("You hire the fighter for %d Ancient Coins" % HIRELING_COST)
	return true


func interact_with_castle_knight(
	player_cell: Vector2i,
	player_inventory: PlayerInventory,
) -> bool:
	var knight: DungeonHireling = null
	for candidate: DungeonHireling in castle_knights:
		if is_instance_valid(candidate) and _are_adjacent(player_cell, candidate.current_cell):
			knight = candidate
			break
	if knight == null:
		return false
	if knight.is_hired:
		companion_event.emit("%s is ready to fight" % knight.get_display_name())
		return true
	if player_inventory == null or player_inventory.get_item_count("Ancient Coin") < CASTLE_KNIGHT_COST:
		companion_event.emit("%s needs %d Ancient Coins" % [knight.get_display_name(), CASTLE_KNIGHT_COST])
		return true

	for _coin_index: int in range(CASTLE_KNIGHT_COST):
		if not player_inventory.remove_item("Ancient Coin"):
			return true
	knight.set_inventory(player_inventory)
	knight.hire()
	companion_event.emit("You hire %s for %d Ancient Coins" % [knight.get_display_name(), CASTLE_KNIGHT_COST])
	return true


func interact_with_prison(player_cell: Vector2i, player_inventory: PlayerInventory) -> bool:
	if prison_room.size == Vector2i.ZERO or not _are_adjacent(player_cell, prison_door_cell):
		return false
	if is_prison_unlocked:
		return true

	if player_inventory == null or player_inventory.get_item_count(BOSS_PRISON_KEY) <= 0:
		prison_event.emit("The Boss Prison is locked. Find a Boss Prison Key.")
		return true

	return unlock_prison(player_inventory)


func unlock_prison(player_inventory: PlayerInventory) -> bool:
	if is_prison_unlocked:
		return true
	if not has_boss() or prison_room.size == Vector2i.ZERO or player_inventory == null:
		if not has_boss():
			prison_event.emit("This expedition has no boss.")
		return false
	if not player_inventory.remove_item(BOSS_PRISON_KEY):
		return false

	is_prison_unlocked = true
	tiles[prison_door_cell.y][prison_door_cell.x] = FLOOR
	var boss: CyclopesEnemy = CyclopesEnemy.new()
	var spawned_boss: DungeonEnemy = spawn_enemy(boss, prison_boss_cell)
	if spawned_boss == null:
		is_prison_unlocked = false
		tiles[prison_door_cell.y][prison_door_cell.x] = WALL
		player_inventory.add_item(BOSS_PRISON_KEY)
		return false

	prison_boss = boss
	prison_event.emit("The Boss Prison opens. The Cyclopes awakens!")
	_refresh_visibility()
	return true


func refresh_visibility() -> void:
	_refresh_visibility()


func is_cell_visible(cell: Vector2i) -> bool:
	return visible_cells.has(cell)


func is_cell_known(cell: Vector2i) -> bool:
	return known_cells.has(cell)


func register_entity(entity: DungeonEntity, starts_immediately: bool = false) -> void:
	if entity == null:
		return

	if not entities.has(entity):
		entities.append(entity)
	if turn_scheduler != null and not turn_scheduler.has_entity(entity):
		turn_scheduler.add_entity(entity, starts_immediately)
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


func suspend_player(player: DungeonEntity) -> void:
	if player == null or active_player != player:
		return
	_player_action_in_progress = false
	_non_player_action_queue.clear()
	_active_non_player = null
	active_player = null
	unregister_entity(player)
	_refresh_visibility()


func attach_player(player: DungeonEntity, cell: Vector2i) -> void:
	if player == null:
		return
	player.setup(self, cell)
	if not entities.has(player):
		register_entity(player)
	if active_player == null:
		_set_active_player(player)
	_refresh_visibility()


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


func spawn_enemy(
	enemy: DungeonEnemy,
	cell: Vector2i,
	starts_immediately: bool = false,
) -> DungeonEnemy:
	if enemy == null or not is_walkable(cell):
		return null
	if (
		get_entity_at(cell) != null
		or _has_pickup_at(cell)
		or get_booby_trap_at(cell) != null
		or get_vendor_at(cell) != null
	):
		return null

	enemy.setup(self, cell)
	enemy.remember_base_attack_damage()
	enemy.apply_difficulty_damage_modifier(get_enemy_damage_modifier())
	enemies.append(enemy)
	# Timed spawns pass starts_immediately so slow enemies are eligible for the
	# next player turn instead of appearing inert beside the player.
	register_entity(enemy, starts_immediately)
	add_child(enemy)
	_refresh_visibility()
	return enemy


func get_available_monster_spawn_cells(blocked_cell: Vector2i) -> Array[Vector2i]:
	var available_cells: Array[Vector2i] = []
	for y: int in range(map_height):
		for x: int in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and is_cell_on_side(cell, monster_spawn_side)
				and cell != start_cell
				and cell != exit_cell
				and cell != blocked_cell
				and cell != hireling_cell
				and not prison_room.has_point(cell)
				and not vendor_room.has_point(cell)
				and not is_safe_area_cell(cell)
				and get_entity_at(cell) == null
				and not _has_pickup_at(cell)
			):
				available_cells.append(cell)
	return available_cells


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
	pickup.setup(item_name, cell, weapon, HealingItemData.from_name(item_name))
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
		if quest_board != null and is_instance_valid(quest_board):
			quest_board.notify_item_collected(item_name)
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


func spawn_booby_trap(cell: Vector2i) -> BoobyTrap:
	if (
		not is_walkable(cell)
		or get_entity_at(cell) != null
		or _has_pickup_at(cell)
		or get_booby_trap_at(cell) != null
	):
		return null

	var trap: BoobyTrap = BoobyTrap.new()
	trap.setup(cell)
	add_child(trap)
	booby_traps.append(trap)
	_refresh_visibility()
	return trap


func get_booby_trap_at(cell: Vector2i) -> BoobyTrap:
	for index: int in range(booby_traps.size() - 1, -1, -1):
		var trap: BoobyTrap = booby_traps[index]
		if not is_instance_valid(trap):
			booby_traps.remove_at(index)
			continue
		if trap.cell == cell:
			return trap
	return null


func clear_booby_traps() -> void:
	for trap: BoobyTrap in booby_traps:
		if is_instance_valid(trap):
			trap.queue_free()
	booby_traps.clear()


func _spawn_booby_traps() -> void:
	clear_booby_traps()
	if is_impossible_trial:
		return

	var candidate_cells: Array[Vector2i] = []
	for y: int in range(map_height):
		for x: int in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and cell != start_cell
				and cell != exit_cell
				and cell != hireling_cell
				and not prison_room.has_point(cell)
				and not monster_spawn_cells.has(cell)
				and not vendor_room.has_point(cell)
				and not is_safe_area_cell(cell)
				and not _has_pickup_at(cell)
			):
				candidate_cells.append(cell)

	var trap_count: int = mini(BOOBY_TRAP_COUNT, candidate_cells.size())
	for _trap_index: int in range(trap_count):
		spawn_booby_trap(_take_random_candidate(candidate_cells))


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


func _create_edge_room(side: int) -> Rect2i:
	var room_width: int = _random.randi_range(4, 6)
	var room_height: int = _random.randi_range(4, 5)
	var room_position: Vector2i = Vector2i.ZERO
	match side:
		MapSide.LEFT:
			room_position = Vector2i(
				0,
				_random.randi_range(1, map_height - room_height - 1),
			)
		MapSide.RIGHT:
			room_position = Vector2i(
				map_width - room_width,
				_random.randi_range(1, map_height - room_height - 1),
			)
		MapSide.TOP:
			room_position = Vector2i(
				_random.randi_range(1, map_width - room_width - 1),
				0,
			)
		MapSide.BOTTOM:
			room_position = Vector2i(
				_random.randi_range(1, map_width - room_width - 1),
				map_height - room_height,
			)
	return Rect2i(room_position, Vector2i(room_width, room_height))


func _build_prison(rooms: Array[Rect2i]) -> void:
	prison_room = _choose_prison_room(rooms)
	if prison_room.size == Vector2i.ZERO or rooms.is_empty():
		return

	var room_center: Vector2i = prison_room.get_center()
	var anchor_cell: Vector2i = _find_nearest_room_center(rooms, room_center)
	var difference: Vector2i = anchor_cell - room_center
	var door_direction: Vector2i
	if abs(difference.x) >= abs(difference.y):
		door_direction = Vector2i(-1, 0) if difference.x < 0 else Vector2i(1, 0)
	else:
		door_direction = Vector2i(0, -1) if difference.y < 0 else Vector2i(0, 1)

	prison_door_cell = _get_prison_edge_cell(prison_room, door_direction)
	var approach_cell: Vector2i = prison_door_cell + door_direction
	prison_boss_cell = room_center

	_carve_room(prison_room)
	_carve_corridor(anchor_cell, approach_cell)
	_wall_prison_boundary()


func _choose_prison_room(rooms: Array[Rect2i]) -> Rect2i:
	var clear_candidates: Array[Rect2i] = []
	var best_candidate: Rect2i = Rect2i()
	var best_blocked_cell_count: int = 1_000_000

	for y in range(PRISON_ROOM_MARGIN, map_height - PRISON_ROOM_SIZE.y - PRISON_ROOM_MARGIN + 1):
		for x in range(PRISON_ROOM_MARGIN, map_width - PRISON_ROOM_SIZE.x - PRISON_ROOM_MARGIN + 1):
			var candidate: Rect2i = Rect2i(Vector2i(x, y), PRISON_ROOM_SIZE)
			if _overlaps_any_room(candidate.grow(1), rooms):
				continue

			var blocked_cell_count: int = _count_walkable_cells(candidate.grow(1))
			if blocked_cell_count == 0:
				clear_candidates.append(candidate)
			if blocked_cell_count < best_blocked_cell_count:
				best_blocked_cell_count = blocked_cell_count
				best_candidate = candidate

	if not clear_candidates.is_empty():
		return clear_candidates[_random.randi_range(0, clear_candidates.size() - 1)]
	return best_candidate


func _overlaps_any_room(candidate: Rect2i, rooms: Array[Rect2i]) -> bool:
	for room: Rect2i in rooms:
		if (
			candidate.position.x < room.end.x
			and candidate.end.x > room.position.x
			and candidate.position.y < room.end.y
			and candidate.end.y > room.position.y

		):
			return true
	return false


func _count_walkable_cells(area: Rect2i) -> int:
	var count: int = 0
	for y in range(area.position.y, area.end.y):
		for x in range(area.position.x, area.end.x):
			if is_walkable(Vector2i(x, y)):
				count += 1
	return count


func _find_nearest_room_center(rooms: Array[Rect2i], target_cell: Vector2i) -> Vector2i:
	var nearest_cell: Vector2i = rooms[0].get_center()
	var nearest_distance: int = 1_000_000
	for room: Rect2i in rooms:
		var room_center: Vector2i = room.get_center()
		var distance: int = absi(room_center.x - target_cell.x) + absi(room_center.y - target_cell.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = room_center
	return nearest_cell


func _get_prison_edge_cell(room: Rect2i, direction: Vector2i) -> Vector2i:
	var room_center: Vector2i = room.get_center()
	if direction.x < 0:
		return Vector2i(room.position.x, room_center.y)
	if direction.x > 0:
		return Vector2i(room.end.x - 1, room_center.y)
	if direction.y < 0:
		return Vector2i(room_center.x, room.position.y)
	return Vector2i(room_center.x, room.end.y - 1)


func _wall_prison_boundary() -> void:
	for y in range(prison_room.position.y, prison_room.end.y):
		for x in range(prison_room.position.x, prison_room.end.x):
			if (
				x == prison_room.position.x
				or x == prison_room.end.x - 1
				or y == prison_room.position.y
				or y == prison_room.end.y - 1
			):
				tiles[y][x] = WALL
	if prison_door_cell != Vector2i.ZERO:
		tiles[prison_door_cell.y][prison_door_cell.x] = WALL


func _get_edge_cell(room: Rect2i, side: int) -> Vector2i:
	var room_center: Vector2i = room.get_center()
	match side:
		MapSide.LEFT:
			return Vector2i(room.position.x, room_center.y)
		MapSide.RIGHT:
			return Vector2i(room.end.x - 1, room_center.y)
		MapSide.TOP:
			return Vector2i(room_center.x, room.position.y)
		MapSide.BOTTOM:
			return Vector2i(room_center.x, room.end.y - 1)
	return room_center


func _get_opposite_side(side: int) -> int:
	match side:
		MapSide.LEFT:
			return MapSide.RIGHT
		MapSide.RIGHT:
			return MapSide.LEFT
		MapSide.TOP:
			return MapSide.BOTTOM
		MapSide.BOTTOM:
			return MapSide.TOP
	return MapSide.RIGHT


func _reserve_monster_spawn_cells() -> Array[Vector2i]:
	var available_cells: Array[Vector2i] = []
	for y: int in range(map_height):
		for x: int in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and is_cell_on_side(cell, monster_spawn_side)
				and cell != start_cell
				and cell != exit_cell
				and not prison_room.has_point(cell)
				and not vendor_room.has_point(cell)
				and not is_safe_area_cell(cell)
			):
				available_cells.append(cell)

	var reserved_cells: Array[Vector2i] = []
	var reservation_count: int = mini(MONSTER_COUNT, available_cells.size())
	for _monster_index: int in range(reservation_count):
		reserved_cells.append(_take_random_candidate(available_cells))
	return reserved_cells


func _reserve_trial_spawn_cells() -> Array[Vector2i]:
	var available_cells: Array[Vector2i] = []
	for y: int in range(map_height):
		for x: int in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and is_cell_on_side(cell, monster_spawn_side)
				and cell != start_cell
				and cell != exit_cell
			):
				available_cells.append(cell)

	var reserved_cells: Array[Vector2i] = []
	var reservation_count: int = mini(TRIAL_CYCLOPES_COUNT, available_cells.size())
	for _cyclopes_index: int in range(reservation_count):
		reserved_cells.append(_take_random_candidate(available_cells))
	return reserved_cells


func _spawn_items() -> void:
	clear_pickups()
	prison_key_cell = Vector2i.ZERO

	var candidate_cells: Array[Vector2i] = []
	for y in range(map_height):
		for x in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and cell != start_cell
				and cell != exit_cell
				and cell != hireling_cell
				and not prison_room.has_point(cell)
				and not monster_spawn_cells.has(cell)
				and not vendor_room.has_point(cell)
				and not is_safe_area_cell(cell)
			):
				candidate_cells.append(cell)

	if not candidate_cells.is_empty():
		prison_key_cell = _take_random_candidate(candidate_cells)
		spawn_pickup(BOSS_PRISON_KEY, prison_key_cell)

	var item_count: int = mini(ITEM_COUNT, candidate_cells.size())
	for item_index in range(item_count):
		var cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_pickup(ITEM_NAMES[item_index % ITEM_NAMES.size()], cell)

	var healing_item_count: int = mini(HEALING_ITEM_NAMES.size(), candidate_cells.size())
	for healing_item_index in range(healing_item_count):
		var healing_item_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_pickup(HEALING_ITEM_NAMES[healing_item_index], healing_item_cell)

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
	for cell: Vector2i in monster_spawn_cells:
		if (
			not is_walkable(cell)
			or cell == start_cell
			or cell == exit_cell
			or cell == hireling_cell
			or prison_room.has_point(cell)
			or vendor_room.has_point(cell)
			or is_safe_area_cell(cell)
		):
			continue
		if get_entity_at(cell) != null or _has_pickup_at(cell):
			continue
		candidate_cells.append(cell)

	if candidate_cells.is_empty():
		return

	if is_impossible_trial:
		for _cyclopes_index: int in range(mini(TRIAL_CYCLOPES_COUNT, candidate_cells.size())):
			var cyclopes_cell: Vector2i = _take_random_candidate(candidate_cells)
			spawn_enemy(CyclopesEnemy.new(), cyclopes_cell)
		return

	var zombie_cell: Vector2i = _take_random_candidate(candidate_cells)
	spawn_enemy(ZombieEnemy.new(), zombie_cell)
	if not candidate_cells.is_empty():
		var skeleton_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(SkeletonEnemy.new(), skeleton_cell)
	for _extra_skeleton_index: int in range(4):
		if candidate_cells.is_empty():
			break
		var extra_skeleton_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(SkeletonEnemy.new(), extra_skeleton_cell)
	if not candidate_cells.is_empty():
		var vampire_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(VampireEnemy.new(), vampire_cell)
	if not candidate_cells.is_empty():
		var spider_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(SpiderEnemy.new(), spider_cell)
	if not candidate_cells.is_empty():
		var ghost_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(GhostEnemy.new(), ghost_cell)
	if not candidate_cells.is_empty():
		var goblin_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(GoblinEnemy.new(), goblin_cell)
	if not candidate_cells.is_empty():
		var orc_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(OrcEnemy.new(), orc_cell)
	if not candidate_cells.is_empty():
		var slime_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(SlimeEnemy.new(), slime_cell)
	if not candidate_cells.is_empty():
		var mummy_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(MummyEnemy.new(), mummy_cell)
	if not candidate_cells.is_empty():
		var wraith_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(WraithEnemy.new(), wraith_cell)
	if not candidate_cells.is_empty():
		var golem_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(GolemEnemy.new(), golem_cell)
	if not candidate_cells.is_empty():
		var lich_cell: Vector2i = _take_random_candidate(candidate_cells)
		spawn_enemy(LichEnemy.new(), lich_cell)


func _spawn_monster_spawner() -> void:
	if is_impossible_trial:
		return
	if monster_spawner != null and is_instance_valid(monster_spawner):
		return
	if not is_walkable(exit_cell) or get_entity_at(exit_cell) != null:
		return

	monster_spawner = MonsterSpawner.new()
	monster_spawner.setup(self, exit_cell)
	add_child(monster_spawner)


func _clear_monster_spawner() -> void:
	if monster_spawner == null or not is_instance_valid(monster_spawner):
		monster_spawner = null
		return
	unregister_entity(monster_spawner)
	monster_spawner.queue_free()
	monster_spawner = null


func _clear_enemies() -> void:
	_non_player_action_queue.clear()
	_active_non_player = null
	for enemy: DungeonEnemy in enemies.duplicate():
		if is_instance_valid(enemy):
			unregister_entity(enemy)
			enemy.queue_free()
	enemies.clear()


func respawn_all_mobs() -> void:
	if is_impossible_trial:
		return
	prison_boss = null
	_clear_enemies()
	_clear_monster_spawner()
	_spawn_enemies()
	if is_prison_unlocked:
		var boss: CyclopesEnemy = CyclopesEnemy.new()
		var boss_cell: Vector2i = _find_available_respawn_cell(prison_boss_cell)
		if spawn_enemy(boss, boss_cell) != null:
			prison_boss = boss
	if should_spawn_monster_spawner():
		_spawn_monster_spawner()
	_refresh_visibility()


func _find_available_respawn_cell(preferred_cell: Vector2i) -> Vector2i:
	var candidates: Array[Vector2i] = [preferred_cell]
	for direction: Vector2i in [
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(0, -1),
		Vector2i(0, 1),
	]:
		candidates.append(preferred_cell + direction)

	for y: int in range(map_height):
		for x: int in range(map_width):
			candidates.append(Vector2i(x, y))

	for cell: Vector2i in candidates:
		if (
			is_walkable(cell)
			and get_entity_at(cell) == null
			and not _has_pickup_at(cell)
			and get_vendor_at(cell) == null
			and not is_safe_area_cell(cell)
		):
			return cell
	return preferred_cell


func _clear_hireling() -> void:
	if hireling == null or not is_instance_valid(hireling):
		hireling = null
		return
	unregister_entity(hireling)
	hireling.queue_free()
	hireling = null


func _clear_castle() -> void:
	for knight: DungeonHireling in castle_knights:
		if is_instance_valid(knight):
			unregister_entity(knight)
			knight.queue_free()
	castle_knights.clear()
	if quest_board != null and is_instance_valid(quest_board):
		quest_board.queue_free()
	quest_board = null
	for npc: DungeonCastleNpc in castle_npcs:
		if is_instance_valid(npc):
			npc.queue_free()
	castle_npcs.clear()
	if weapon_shop != null and is_instance_valid(weapon_shop):
		weapon_shop.queue_free()
	if healing_shop != null and is_instance_valid(healing_shop):
		healing_shop.queue_free()
	weapon_shop = null
	healing_shop = null
	weapon_shop_cell = Vector2i.ZERO
	healing_shop_cell = Vector2i.ZERO


func _create_castle_area(_start_room: Rect2i) -> Rect2i:
	var position: Vector2i = Vector2i(
		(map_width - CASTLE_SIZE.x) / 2,
		(map_height - CASTLE_SIZE.y) / 2,
	)
	return Rect2i(position, CASTLE_SIZE)


func _carve_castle_area(area: Rect2i) -> void:
	var interior: Rect2i = area.grow(-1)
	_carve_room(interior)


func _seal_castle_walls(area: Rect2i) -> void:
	for x: int in range(area.position.x, area.end.x):
		tiles[area.position.y][x] = WALL
		tiles[area.end.y - 1][x] = WALL
	for y: int in range(area.position.y, area.end.y):
		tiles[y][area.position.x] = WALL
		tiles[y][area.end.x - 1] = WALL


func _spawn_castle() -> void:
	weapon_shop_cell = castle_area.position + Vector2i(3, 3)
	healing_shop_cell = castle_area.position + Vector2i(8, 3)
	weapon_shop = DungeonShop.new()
	weapon_shop.configure_shop(DungeonShop.ShopType.WEAPONS)
	weapon_shop.setup(self, weapon_shop_cell)
	add_child(weapon_shop)
	healing_shop = DungeonShop.new()
	healing_shop.configure_shop(DungeonShop.ShopType.HEALING)
	healing_shop.setup(self, healing_shop_cell)
	add_child(healing_shop)

	var npc_specs: Array[Dictionary] = [
		{
			"cell": castle_area.position + Vector2i(6, 1),
			"name": "Captain Elara",
			"dialogue": "Keep your blade sheathed within the castle. The warded stones hold the dungeon at bay.",
		},
		{
			"cell": castle_area.position + Vector2i(6, 7),
			"name": "Archivist Noll",
			"dialogue": "The gate is safe ground. Rest, trade, and gather your courage before descending again.",
		},
	]
	for npc_spec: Dictionary in npc_specs:
		var npc: DungeonCastleNpc = DungeonCastleNpc.new()
		npc.setup(
			self,
			Vector2i(npc_spec["cell"]),
			str(npc_spec["name"]),
			str(npc_spec["dialogue"]),
		)
		castle_npcs.append(npc)
		add_child(npc)

	var knight_specs: Array[Dictionary] = [
		{
			"cell": castle_area.position + Vector2i(2, 6),
			"name": "Sir Rowan",
		},
		{
			"cell": castle_area.position + Vector2i(6, 6),
			"name": "Dame Maris",
		},
		{
			"cell": castle_area.position + Vector2i(9, 6),
			"name": "Ser Kael",
		},
	]
	for knight_spec: Dictionary in knight_specs:
		var knight: DungeonHireling = DungeonHireling.new()
		knight.set_companion_name(str(knight_spec["name"]))
		knight.setup(self, Vector2i(knight_spec["cell"]))
		castle_knights.append(knight)
		add_child(knight)

	quest_board = DungeonQuestBoard.new()
	quest_board.configure_for_difficulty(difficulty)
	quest_board.setup(self, castle_area.position + Vector2i(6, 4))
	add_child(quest_board)


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
	for y: int in range(map_height):
		for x: int in range(map_width):
			var cell: Vector2i = Vector2i(x, y)
			if (
				is_walkable(cell)
				and cell != start_cell
				and cell != exit_cell
				and not prison_room.has_point(cell)
				and not monster_spawn_cells.has(cell)
				and not vendor_room.has_point(cell)
				and not is_safe_area_cell(cell)
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
		_queue_boss_attack_if_in_range()
		_run_next_non_player_action()
		return

	if entity == _active_non_player:
		_active_non_player = null
		_run_next_non_player_action()


func _on_entity_movement_finished(entity: DungeonEntity, cell: Vector2i) -> void:
	var trap: BoobyTrap = get_booby_trap_at(cell)
	if trap != null:
		var damage_dealt: int = trap.activate(entity)
		if damage_dealt > 0:
			combat_event.emit(
				"%s triggers a booby trap and loses %d heart%s" % [
					entity.get_display_name(),
					damage_dealt,
					"" if damage_dealt == 1 else "s",
				]
			)
	_refresh_visibility()


func _queue_boss_attack_if_in_range() -> void:
	var boss: CyclopesEnemy = get_prison_boss()
	var player: DungeonEntity = get_player()
	if (
		boss == null
		or player == null
		or boss.is_action_in_progress()
		or _active_non_player != null
		or _non_player_action_queue.has(boss)
	):
		return

	var difference: Vector2i = player.current_cell - boss.current_cell
	var distance: int = abs(difference.x) + abs(difference.y)
	if distance <= 0 or distance > boss.get_attack_range():
		return

	if turn_scheduler != null and not turn_scheduler.has_entity(boss):
		turn_scheduler.add_entity(boss)
	_non_player_action_queue.push_front(boss)


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
		var replacement_companion: DungeonHireling = _get_hired_companion(entity)
		if replacement_companion != null:
			var defeated_player: DungeonEntity = active_player
			unregister_entity(defeated_player)
			_set_active_player(replacement_companion)
			companion_event.emit("You take control of %s" % replacement_companion.get_display_name())
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
		if quest_board != null and is_instance_valid(quest_board):
			quest_board.notify_enemy_defeated(entity.get_display_name())
		if entity == prison_boss:
			prison_boss = null
		unregister_entity(entity)
		if is_impossible_trial and enemies.is_empty():
			trial_completed.emit()


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


func _get_hired_companion(excluded_entity: DungeonEntity = null) -> DungeonHireling:
	if (
		hireling != null
		and is_instance_valid(hireling)
		and hireling != excluded_entity
		and hireling.is_hired
		and not hireling.health.is_depleted()
	):
		return hireling
	for knight: DungeonHireling in castle_knights:
		if (
			is_instance_valid(knight)
			and knight != excluded_entity
			and knight.is_hired
			and not knight.health.is_depleted()
		):
			return knight
	for entity: DungeonEntity in entities:
		var companion: DungeonHireling = entity as DungeonHireling
		if (
			companion != null
			and companion != excluded_entity
			and companion.is_hired
			and not companion.health.is_depleted()
		):
			return companion
	return null


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

	for trap: BoobyTrap in booby_traps:
		if not is_instance_valid(trap):
			continue
		trap.set_explored_state(is_cell_visible(trap.cell), is_cell_known(trap.cell))

	if vendor != null and is_instance_valid(vendor):
		vendor.set_explored_state(is_cell_visible(vendor.cell), is_cell_known(vendor.cell))
	for shop: DungeonShop in [weapon_shop, healing_shop]:
		if shop != null and is_instance_valid(shop):
			shop.set_explored_state(is_cell_visible(shop.cell), is_cell_known(shop.cell))
	for npc: DungeonCastleNpc in castle_npcs:
		if is_instance_valid(npc):
			npc.set_explored_state(is_cell_visible(npc.cell), is_cell_known(npc.cell))
	if quest_board != null and is_instance_valid(quest_board):
		quest_board.set_explored_state(
			is_cell_visible(quest_board.cell),
			is_cell_known(quest_board.cell),
		)

	queue_redraw()


func _is_opaque_for_field_of_view(cell: Vector2i) -> bool:
	return not is_walkable(cell)


func _draw() -> void:
	var map_size: Vector2 = get_map_size()
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#0b0e15"))

	for y in range(map_height):
		for x in range(map_width):
			var tile_rect: Rect2 = Rect2(
				Vector2(x * TILE_SIZE, y * TILE_SIZE),
				Vector2(TILE_SIZE, TILE_SIZE)
			)
			var cell: Vector2i = Vector2i(x, y)
			if not is_cell_known(cell):
				draw_rect(tile_rect, Color("#080a10"))
				continue

			var is_floor: bool = tiles.size() == map_height and tiles[y][x] == FLOOR
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
	if castle_entry_stairs_cell != Vector2i.ZERO and is_cell_known(castle_entry_stairs_cell):
		_draw_stairs(castle_entry_stairs_cell)
	if is_castle_entered and castle_entry_cell != Vector2i.ZERO and is_cell_known(castle_entry_cell):
		_draw_stairs(castle_entry_cell)
	if vendor_room.size != Vector2i.ZERO and is_cell_known(vendor_cell):
		var room_rect: Rect2 = Rect2(
			Vector2(vendor_room.position * TILE_SIZE),
			Vector2(vendor_room.size * TILE_SIZE),
		)
		draw_rect(room_rect.grow(-2.0), Color(0.84, 0.66, 0.37, 0.38), false, 2.0)
	_draw_castle()
	_draw_above_ground_castle()
	_draw_prison_room()


func _draw_above_ground_castle() -> void:
	if above_ground_castle_area.size == Vector2i.ZERO:
		return

	var castle_rect: Rect2 = Rect2(
		Vector2(above_ground_castle_area.position * TILE_SIZE),
		Vector2(above_ground_castle_area.size * TILE_SIZE),
	)
	var wall_color: Color = Color("#c59b58")
	var shadow_color: Color = Color("#594b3b")
	var inner_color: Color = Color("#e4c16d")
	draw_rect(castle_rect.grow(-5.0), shadow_color, false, 8.0)
	draw_rect(castle_rect.grow(-11.0), wall_color.darkened(0.2), false, 3.0)

	var keep_size: Vector2i = Vector2i(18, 12)
	var keep_position: Vector2i = above_ground_castle_area.get_center() - keep_size / 2
	var keep_rect: Rect2 = Rect2(
		Vector2(keep_position * TILE_SIZE),
		Vector2(keep_size * TILE_SIZE),
	)
	draw_rect(keep_rect.grow(-4.0), shadow_color.darkened(0.2), false, 5.0)
	draw_rect(keep_rect.grow(-10.0), inner_color.darkened(0.45), false, 2.0)

	for tower_offset: Vector2i in [
		Vector2i(1, 1),
		Vector2i(above_ground_castle_area.size.x - 2, 1),
		Vector2i(1, above_ground_castle_area.size.y - 2),
		Vector2i(above_ground_castle_area.size.x - 2, above_ground_castle_area.size.y - 2),
	]:
		var tower_center: Vector2 = cell_to_world(above_ground_castle_area.position + tower_offset)
		draw_circle(tower_center, 18.0, shadow_color)
		draw_circle(tower_center, 13.0, wall_color.darkened(0.1))
		draw_arc(tower_center, 15.0, 0.0, TAU, 20, inner_color, 2.0)


func _draw_castle() -> void:
	if castle_area.size == Vector2i.ZERO:
		return
	var castle_is_known: bool = false
	for y: int in range(castle_area.position.y, castle_area.end.y):
		for x: int in range(castle_area.position.x, castle_area.end.x):
			if is_cell_known(Vector2i(x, y)):
				castle_is_known = true
				break
		if castle_is_known:
			break
	if not castle_is_known:
		return

	var castle_rect: Rect2 = Rect2(
		Vector2(castle_area.position * TILE_SIZE),
		Vector2(castle_area.size * TILE_SIZE),
	)
	draw_rect(castle_rect.grow(-3.0), Color("#b88c4f").darkened(0.35), false, 3.0)
	draw_rect(castle_rect.grow(-8.0), Color("#d6a85f").darkened(0.45), false, 1.0)
	for tower_offset: Vector2i in [
		Vector2i(0, 0),
		Vector2i(castle_area.size.x - 1, 0),
		Vector2i(0, castle_area.size.y - 1),
		Vector2i(castle_area.size.x - 1, castle_area.size.y - 1),
	]:
		var tower_cell: Vector2i = castle_area.position + tower_offset
		if not is_cell_known(tower_cell):
			continue
		draw_circle(cell_to_world(tower_cell), 11.0, Color("#594b3b"))
		draw_arc(cell_to_world(tower_cell), 11.0, 0.0, TAU, 16, Color("#e4c16d"), 2.0)


func _draw_prison_room() -> void:
	if prison_room.size == Vector2i.ZERO:
		return
	if not is_cell_known(prison_door_cell) and not is_cell_known(prison_boss_cell):
		return

	var room_rect: Rect2 = Rect2(
		Vector2(prison_room.position * TILE_SIZE),
		Vector2(prison_room.size * TILE_SIZE),
	)
	var border_color: Color = Color("#e85f70") if not is_prison_unlocked else Color("#b88c4f")
	draw_rect(room_rect.grow(-2.0), border_color.darkened(0.38), false, 2.0)

	if is_cell_known(prison_door_cell):
		var door_rect: Rect2 = Rect2(
			Vector2(prison_door_cell * TILE_SIZE) + Vector2(6.0, 6.0),
			Vector2(TILE_SIZE - 12.0, TILE_SIZE - 12.0),
		)
		var door_color: Color = Color("#e85f70") if not is_prison_unlocked else Color("#b88c4f")
		draw_rect(door_rect, door_color, false, 2.0)
		if not is_prison_unlocked:
			draw_line(
				door_rect.position + Vector2(5.0, 5.0),
				door_rect.end - Vector2(5.0, 5.0),
				door_color,
				2.0,
			)
			draw_line(
				Vector2(door_rect.end.x - 5.0, door_rect.position.y + 5.0),
				Vector2(door_rect.position.x + 5.0, door_rect.end.y - 5.0),
				door_color,
				2.0,
			)


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


func _draw_stairs(cell: Vector2i) -> void:
	var center: Vector2 = cell_to_world(cell)
	var stair_color: Color = Color("#e4c16d") if is_cell_visible(cell) else Color("#876d43")
	for stair_index: int in range(3):
		var y_offset: float = -8.0 + float(stair_index) * 8.0
		draw_line(
			center + Vector2(-9.0, y_offset),
			center + Vector2(9.0, y_offset),
			stair_color,
			2.0,
		)
