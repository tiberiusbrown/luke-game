class_name WraithEnemy
extends DungeonEnemy

const HEALTH: int = 7
const SPEED: float = 1.5
const ATTACK_DAMAGE: int = 2
const HIT_CHANCE: float = 0.65


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Wraith"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 11.0, Color(0.0, 0.0, 0.0, 0.2))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10, 10),
			Vector2(-9, -2),
			Vector2(-6, -9),
			Vector2(0, -12),
			Vector2(7, -8),
			Vector2(10, -1),
			Vector2(9, 10),
			Vector2(4, 6),
			Vector2(0, 10),
			Vector2(-5, 6),
		]),
		Color(0.31, 0.24, 0.53, 0.88),
	)
	draw_circle(Vector2(0, -3), 8.0, Color(0.54, 0.43, 0.76, 0.9))
	draw_circle(Vector2(-3, -4), 1.7, Color("#d7a9ff"))
	draw_circle(Vector2(3, -4), 1.7, Color("#d7a9ff"))
	draw_line(Vector2(-4, 2), Vector2(4, 2), Color("#2b224d"), 1.4)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#b897e8"), 1.5)
