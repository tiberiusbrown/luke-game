class_name MummyEnemy
extends DungeonEnemy

const HEALTH: int = 12
const SPEED: float = 0.75
const ATTACK_DAMAGE: int = 2
const HIT_CHANCE: float = 0.65


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Mummy"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10, 10),
			Vector2(-8, -2),
			Vector2(-6, -10),
			Vector2(6, -10),
			Vector2(8, -2),
			Vector2(10, 10),
		]),
		Color("#a78662"),
	)
	draw_circle(Vector2(0, -4), 8.0, Color("#d9c59a"))
	draw_line(Vector2(-7, -7), Vector2(7, -5), Color("#8c6a4e"), 1.5)
	draw_line(Vector2(-8, -2), Vector2(8, 0), Color("#8c6a4e"), 1.5)
	draw_line(Vector2(-7, 3), Vector2(7, 5), Color("#8c6a4e"), 1.5)
	draw_circle(Vector2(-3, -4), 1.5, Color("#7b3541"))
	draw_circle(Vector2(3, -4), 1.5, Color("#7b3541"))
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#ead6a8"), 1.5)
