class_name LichEnemy
extends DungeonEnemy

const HEALTH: int = 8
const SPEED: float = 1.0
const ATTACK_DAMAGE: int = 3
const HIT_CHANCE: float = 0.60


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Lich"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-11, 10),
			Vector2(-7, -1),
			Vector2(-5, -8),
			Vector2(5, -8),
			Vector2(7, -1),
			Vector2(11, 10),
		]),
		Color("#352d58"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-7, -7),
			Vector2(-4, -12),
			Vector2(0, -9),
			Vector2(4, -12),
			Vector2(7, -7),
		]),
		Color("#b88c4f"),
	)
	draw_circle(Vector2(0, -3), 8.0, Color("#d8d3ca"))
	draw_circle(Vector2(-3, -4), 1.8, Color("#9e4eff"))
	draw_circle(Vector2(3, -4), 1.8, Color("#9e4eff"))
	draw_line(Vector2(-4, 3), Vector2(4, 3), Color("#686372"), 1.3)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#bd9de9"), 1.5)
