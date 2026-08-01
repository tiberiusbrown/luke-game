class_name SpiderEnemy
extends DungeonEnemy

const HEALTH: int = 5
const SPEED: float = DungeonPlayer.SPEED
const ATTACK_DAMAGE: int = 1
const HIT_CHANCE: float = 1.0


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Spider"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE


func _draw() -> void:
	draw_circle(Vector2(2, 6), 11.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_line(Vector2(-5, -3), Vector2(-14, -10), Color("#31353e"), 2.0)
	draw_line(Vector2(-7, 0), Vector2(-16, -2), Color("#31353e"), 2.0)
	draw_line(Vector2(-7, 4), Vector2(-15, 9), Color("#31353e"), 2.0)
	draw_line(Vector2(5, -3), Vector2(14, -10), Color("#31353e"), 2.0)
	draw_line(Vector2(7, 0), Vector2(16, -2), Color("#31353e"), 2.0)
	draw_line(Vector2(7, 4), Vector2(15, 9), Color("#31353e"), 2.0)
	draw_circle(Vector2.ZERO, 9.5, Color("#252936"))
	draw_circle(Vector2(0, -5), 6.5, Color("#3b4050"))
	draw_circle(Vector2(-3, -6), 1.5, Color("#e56b75"))
	draw_circle(Vector2(3, -6), 1.5, Color("#e56b75"))
	draw_arc(Vector2.ZERO, 9.5, 0.0, TAU, 24, Color("#687184"), 1.5)
