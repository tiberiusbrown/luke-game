class_name SkeletonEnemy
extends DungeonEnemy

const SPEED: float = 1.25
const ATTACK_DAMAGE: int = 1
const HIT_CHANCE: float = 0.75


func _init() -> void:
	super._init()
	enemy_type = "Skeleton"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _on_defeated() -> void:
	var defeated_level: DungeonLevel = dungeon_level
	var defeated_cell: Vector2i = current_cell
	super._on_defeated()
	if defeated_level != null:
		defeated_level.spawn_pickup(DungeonLevel.SKULL_ITEM_NAME, defeated_cell)


func _draw() -> void:
	draw_circle(Vector2(2, 5), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(Vector2.ZERO, 10.5, Color("#6d7480"))
	draw_circle(Vector2(0, -3), 8.5, Color("#d7d9d2"))
	draw_circle(Vector2(-3, -4), 1.8, Color("#293244"))
	draw_circle(Vector2(3, -4), 1.8, Color("#293244"))
	draw_line(Vector2(-4, 2), Vector2(4, 2), Color("#727a83"), 1.4)
	draw_line(Vector2(-4, 5), Vector2(4, 5), Color("#727a83"), 1.4)
	draw_line(Vector2(-4, 8), Vector2(4, 8), Color("#727a83"), 1.4)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#f0eee2"), 1.5)
