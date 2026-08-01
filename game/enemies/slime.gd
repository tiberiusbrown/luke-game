class_name SlimeEnemy
extends DungeonEnemy

const HEALTH: int = 4
const SPEED: float = 1.25
const ATTACK_DAMAGE: int = 1
const HIT_CHANCE: float = 0.90


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Slime"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 11.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-11, 9),
			Vector2(-10, 1),
			Vector2(-7, -7),
			Vector2(-2, -11),
			Vector2(5, -9),
			Vector2(10, -2),
			Vector2(11, 9),
		]),
		Color(0.35, 0.76, 0.54, 0.9),
	)
	draw_circle(Vector2(-3, -2), 2.0, Color("#173b3a"))
	draw_circle(Vector2(4, -2), 2.0, Color("#173b3a"))
	draw_circle(Vector2(-2, -2), 0.7, Color("#d6f5cf"))
	draw_circle(Vector2(5, -2), 0.7, Color("#d6f5cf"))
	draw_arc(Vector2(0, 1), 5.0, 0.2, PI - 0.2, 12, Color("#1d5d51"), 1.4)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#9de5a8"), 1.5)
