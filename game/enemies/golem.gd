class_name GolemEnemy
extends DungeonEnemy

const HEALTH: int = 16
const SPEED: float = 0.5
const ATTACK_DAMAGE: int = 3
const HIT_CHANCE: float = 0.75


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Golem"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 7), 13.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12, 10),
			Vector2(-11, -6),
			Vector2(-7, -12),
			Vector2(7, -12),
			Vector2(11, -6),
			Vector2(12, 10),
		]),
		Color("#686b78"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-8, -9),
			Vector2(8, -9),
			Vector2(7, 4),
			Vector2(-7, 4),
		]),
		Color("#858895"),
	)
	draw_circle(Vector2(-3, -3), 1.7, Color("#f0b45e"))
	draw_circle(Vector2(3, -3), 1.7, Color("#f0b45e"))
	draw_line(Vector2(-5, 7), Vector2(0, 2), Color("#4c4e5a"), 1.5)
	draw_line(Vector2(0, 2), Vector2(6, 8), Color("#4c4e5a"), 1.5)
	draw_arc(Vector2.ZERO, 11.5, 0.0, TAU, 24, Color("#a6a9b4"), 1.5)
