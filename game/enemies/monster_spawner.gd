class_name MonsterSpawner
extends DungeonEntity

const MAX_HEARTS: int = 100
const SPAWN_INTERVAL: float = 5.0
const MONSTERS_PER_SPAWN: int = 10
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

	var candidate_cells: Array[Vector2i] = dungeon_level.get_available_monster_spawn_cells(current_cell)
	candidate_cells.shuffle()
	var spawned_count: int = 0
	var spawn_count: int = mini(MONSTERS_PER_SPAWN, candidate_cells.size())
	for cell: Vector2i in candidate_cells.slice(0, spawn_count):
		var monster: DungeonEnemy = _create_monster()
		if dungeon_level.spawn_enemy(monster, cell) != null:
			spawned_count += 1
	return spawned_count


func _create_monster() -> DungeonEnemy:
	var monster_script: Script = MONSTER_SCRIPTS[
		random_number_generator.randi_range(0, MONSTER_SCRIPTS.size() - 1)
	]
	return monster_script.new() as DungeonEnemy


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
