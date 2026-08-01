class_name GoblinEnemy
extends DungeonEnemy

const HEALTH: int = 6
const SPEED: float = 1.5
const ATTACK_DAMAGE: int = 1
const HIT_CHANCE: float = 0.80


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Goblin"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 5), 10.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-7, -5),
			Vector2(-14, -12),
			Vector2(-11, 1),
		]),
		Color("#567241"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(7, -5),
			Vector2(14, -12),
			Vector2(11, 1),
		]),
		Color("#567241"),
	)
	draw_circle(Vector2.ZERO, 9.5, Color("#6f934b"))
	draw_circle(Vector2(0, -2), 7.5, Color("#9dbb63"))
	draw_circle(Vector2(-3, -3), 1.5, Color("#2d2635"))
	draw_circle(Vector2(3, -3), 1.5, Color("#2d2635"))
	draw_line(Vector2(-4, 3), Vector2(4, 3), Color("#4a392c"), 1.5)
	draw_arc(Vector2.ZERO, 9.5, 0.0, TAU, 24, Color("#b7d47a"), 1.5)
