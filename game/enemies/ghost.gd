class_name GhostEnemy
extends DungeonEnemy

const SPEED: float = DungeonPlayer.SPEED
const ATTACK_DAMAGE: int = 1
const HIT_CHANCE: float = 0.50


func _init() -> void:
	super._init()
	enemy_type = "Ghost"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 11.0, Color(0.0, 0.0, 0.0, 0.2))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-10, 10),
			Vector2(-10, -1),
			Vector2(-7, -8),
			Vector2(0, -12),
			Vector2(7, -8),
			Vector2(10, -1),
			Vector2(10, 10),
			Vector2(5, 6),
			Vector2(0, 10),
			Vector2(-5, 6),
		]),
		Color(0.46, 0.70, 0.86, 0.82),
	)
	draw_circle(Vector2(0, -3), 8.5, Color(0.67, 0.84, 0.94, 0.86))
	draw_circle(Vector2(-3, -4), 1.7, Color("#26364e"))
	draw_circle(Vector2(3, -4), 1.7, Color("#26364e"))
	draw_line(Vector2(-4, 2), Vector2(4, 2), Color("#4b6685"), 1.4)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#b8e0ee"), 1.5)
