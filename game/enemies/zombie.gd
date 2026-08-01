class_name ZombieEnemy
extends DungeonEnemy

const SPEED: float = 0.75
const ATTACK_DAMAGE: int = 2
const HIT_CHANCE: float = 0.50


func _init() -> void:
	super._init()
	enemy_type = "Zombie"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 5), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_circle(Vector2.ZERO, 10.5, Color("#557c61"))
	draw_circle(Vector2(0, -2), 8.5, Color("#79a36e"))
	draw_circle(Vector2(-3, -3), 1.6, Color("#f3d7a0"))
	draw_circle(Vector2(3, -3), 1.6, Color("#f3d7a0"))
	draw_line(Vector2(-4, 3), Vector2(4, 3), Color("#304b3c"), 1.6)
	draw_line(Vector2(-2, 4), Vector2(-1, 6), Color("#304b3c"), 1.2)
	draw_line(Vector2(2, 4), Vector2(1, 6), Color("#304b3c"), 1.2)
	draw_arc(Vector2.ZERO, 10.5, 0.0, TAU, 24, Color("#a5c28c"), 1.5)
