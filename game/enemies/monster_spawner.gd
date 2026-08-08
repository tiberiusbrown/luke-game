class_name MonsterSpawner
extends DungeonEntity

const MAX_HEARTS: int = 100
const SPAWN_INTERVAL: float = 5.0
const MONSTERS_PER_SPAWN: int = 10
const MAX_SPAWNED_MONSTERS: int = 10
const SPAWNED_MONSTER_SPEED_MULTIPLIER: float = 2.0
const SPAWNED_MONSTER_DAMAGE_BONUS: int = 1
const SPAWNED_MONSTER_HIT_CHANCE_BONUS: float = 0.20
const MONSTER_SCRIPTS: Array[Script] = [
	preload("res://game/enemies/zombie.gd"),
	preload("res://game/enemies/skeleton.gd"),
	preload("res://game/enemies/vampire.gd"),
	preload("res://game/enemies/spider.gd"),
	preload("res://game/enemies/ghost.gd"),
	preload("res://game/enemies/goblin.gd"),
	preload("res://game/enemies/orc.gd"),
	preload("res://game/enemies/slime.gd"),
	preload("res://game/enemies/mummy.gd"),
	preload("res://game/enemies/wraith.gd"),
	preload("res://game/enemies/golem.gd"),
	preload("res://game/enemies/lich.gd"),
]

var _time_until_spawn: float = SPAWN_INTERVAL
var _spawned_monsters: Array[DungeonEnemy] = []


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


func _process(delta: float) -> void:
	if dungeon_level == null or health.is_depleted():
		return

	_time_until_spawn -= delta
	while _time_until_spawn <= 0.0:
		spawn_monsters()
		_time_until_spawn += SPAWN_INTERVAL


func spawn_monsters() -> int:
	if dungeon_level == null or health.is_depleted():
		return 0

	_prune_spawned_monsters()
	var remaining_spawn_slots: int = MAX_SPAWNED_MONSTERS - _spawned_monsters.size()
	if remaining_spawn_slots <= 0:
		return 0

	var candidate_cells: Array[Vector2i] = dungeon_level.get_available_monster_spawn_cells(current_cell)
	candidate_cells.shuffle()
	var spawned_count: int = 0
	var spawn_count: int = mini(
		mini(MONSTERS_PER_SPAWN, remaining_spawn_slots),
		candidate_cells.size(),
	)
	for cell: Vector2i in candidate_cells.slice(0, spawn_count):
		var monster: DungeonEnemy = _create_monster()
		_configure_spawned_monster(monster)
		if dungeon_level.spawn_enemy(monster, cell, true) != null:
			_spawned_monsters.append(monster)
			monster.defeated.connect(_on_spawned_monster_defeated)
			spawned_count += 1
	return spawned_count


func get_spawned_monster_count() -> int:
	_prune_spawned_monsters()
	return _spawned_monsters.size()


func _create_monster() -> DungeonEnemy:
	var monster_script: Script = MONSTER_SCRIPTS[
		random_number_generator.randi_range(0, MONSTER_SCRIPTS.size() - 1)
	]
	return monster_script.new() as DungeonEnemy


func _configure_spawned_monster(monster: DungeonEnemy) -> void:
	monster.speed *= SPAWNED_MONSTER_SPEED_MULTIPLIER
	monster.attack_damage += SPAWNED_MONSTER_DAMAGE_BONUS
	monster.hit_chance = clampf(
		monster.hit_chance + SPAWNED_MONSTER_HIT_CHANCE_BONUS,
		0.0,
		1.0,
	)


func _prune_spawned_monsters() -> void:
	for index: int in range(_spawned_monsters.size() - 1, -1, -1):
		var monster: DungeonEnemy = _spawned_monsters[index]
		if (
			not is_instance_valid(monster)
			or monster.health.is_depleted()
		):
			_spawned_monsters.remove_at(index)


func _on_spawned_monster_defeated(entity: DungeonEntity) -> void:
	var monster: DungeonEnemy = entity as DungeonEnemy
	if monster != null:
		_spawned_monsters.erase(monster)


func _on_defeated() -> void:
	set_process(false)
	if dungeon_level != null:
		dungeon_level.unregister_entity(self)
	queue_free()


func _draw() -> void:
	draw_circle(Vector2(3, 8), 18.0, Color(0.0, 0.0, 0.0, 0.42))
	draw_circle(Vector2.ZERO, 16.0, Color("#382b49"))
	draw_circle(Vector2.ZERO, 12.0, Color("#69456f"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(0, -14),
			Vector2(10, -4),
			Vector2(7, 10),
			Vector2(-7, 10),
			Vector2(-10, -4),
		]),
		Color("#d45b72"),
	)
	draw_circle(Vector2(0, -1), 4.0, Color("#ffb06f"))
	draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color("#e3a2c5"), 2.0)
