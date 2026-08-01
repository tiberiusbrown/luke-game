class_name OrcEnemy
extends DungeonEnemy

const HEALTH: int = 14
const SPEED: float = 0.65
const ATTACK_DAMAGE: int = 3
const HIT_CHANCE: float = 0.60


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Orc"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 12.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12, 8),
			Vector2(-10, -3),
			Vector2(-6, -9),
			Vector2(6, -9),
			Vector2(10, -3),
			Vector2(12, 8),
		]),
		Color("#4e6842"),
	)
	draw_circle(Vector2(0, -2), 8.5, Color("#718f51"))
	draw_circle(Vector2(-3, -3), 1.8, Color("#241f2a"))
	draw_circle(Vector2(3, -3), 1.8, Color("#241f2a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-6, 3),
			Vector2(-2, 3),
			Vector2(-4, 8),
		]),
		Color("#f2e2bd"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(2, 3),
			Vector2(6, 3),
			Vector2(4, 8),
		]),
		Color("#f2e2bd"),
	)
	draw_line(Vector2(-7, 1), Vector2(7, 1), Color("#344735"), 1.5)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#a4bb73"), 1.5)
