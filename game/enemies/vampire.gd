class_name VampireEnemy
extends DungeonEnemy

const SPEED: float = DungeonPlayer.SPEED
const ATTACK_DAMAGE: int = 2
const HIT_CHANCE: float = 0.50


func _init() -> void:
	super._init()
	enemy_type = "Vampire"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 5), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12, 10),
			Vector2(12, 10),
			Vector2(8, -1),
			Vector2(0, -10),
			Vector2(-8, -1),
		]),
		Color("#4d243d"),
	)
	draw_circle(Vector2.ZERO, 8.5, Color("#d7b4ae"))
	draw_circle(Vector2(-3, -2), 1.7, Color("#e05c6f"))
	draw_circle(Vector2(3, -2), 1.7, Color("#e05c6f"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-5, 3),
			Vector2(-2, 3),
			Vector2(-3.5, 7),
		]),
		Color("#f3f0e7"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(2, 3),
			Vector2(5, 3),
			Vector2(3.5, 7),
		]),
		Color("#f3f0e7"),
	)
	draw_line(Vector2(-8, -5), Vector2(-5, -10), Color("#8f4564"), 2.0)
	draw_line(Vector2(8, -5), Vector2(5, -10), Color("#8f4564"), 2.0)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#9e4c6b"), 1.5)
