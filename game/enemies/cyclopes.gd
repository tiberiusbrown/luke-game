class_name CyclopesEnemy
extends DungeonEnemy

const HEALTH: int = 30
const SPEED: float = 1.5
const ATTACK_DAMAGE: int = 4
const HIT_CHANCE: float = 0.90
const ATTACK_RANGE: int = 2
const ATTACK_COOLDOWN: float = 0.8
const IS_BOSS: bool = true

var _attack_cooldown: float = 0.0


func _init() -> void:
	super._init()
	health = HeartHealth.new(HEALTH)
	enemy_type = "Cyclopes"
	speed = SPEED
	attack_damage = ATTACK_DAMAGE
	hit_chance = HIT_CHANCE
	is_boss = IS_BOSS


func get_attack_color() -> Color:
	return Color("#e85f70")


func get_attack_range() -> int:
	return ATTACK_RANGE


func take_turn() -> bool:
	return super.take_turn()


func _try_attack(target: DungeonEntity) -> bool:
	var action_started: bool = super._try_attack(target)
	if action_started:
		_attack_cooldown = ATTACK_COOLDOWN
	return action_started


func _process(delta: float) -> void:
	if _attack_cooldown > 0.0:
		_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	if (
		_attack_cooldown > 0.0
		or dungeon_level == null
		or health.is_depleted()
		or is_action_in_progress()
	):
		return

	var target: DungeonEntity = dungeon_level.get_player()
	if target == null or target.health.is_depleted() or target.is_action_in_progress():
		return
	if not _is_in_attack_range(target.current_cell):
		return

	if _try_attack(target):
		_attack_cooldown = ATTACK_COOLDOWN


func _draw() -> void:
	draw_circle(Vector2(3, 9), 16.0, Color(0.0, 0.0, 0.0, 0.38))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-14, 13),
			Vector2(-16, -3),
			Vector2(-11, -13),
			Vector2(-6, -17),
			Vector2(6, -17),
			Vector2(11, -13),
			Vector2(16, -3),
			Vector2(14, 13),
		]),
		Color("#6b3948"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-12, -11),
			Vector2(-17, -18),
			Vector2(-11, -17),
			Vector2(-7, -12),
		]),
		Color("#c78a58"),
	)
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(12, -11),
			Vector2(17, -18),
			Vector2(11, -17),
			Vector2(7, -12),
		]),
		Color("#c78a58"),
	)
	draw_circle(Vector2.ZERO, 13.0, Color("#a95d62"))
	draw_circle(Vector2(0, -2), 10.5, Color("#d18a76"))
	draw_circle(Vector2.ZERO, 5.5, Color("#f3d48b"))
	draw_circle(Vector2.ZERO, 3.5, Color("#302237"))
	draw_circle(Vector2(-1.2, -1.5), 1.2, Color("#fff2c2"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-8, 6),
			Vector2(-3, 4),
			Vector2(0, 8),
			Vector2(3, 4),
			Vector2(8, 6),
			Vector2(5, 11),
			Vector2(-5, 11),
		]),
		Color("#4b2937"),
	)
	draw_arc(Vector2.ZERO, 15.0, 0.0, TAU, 28, Color("#f0ad7f"), 2.0)
