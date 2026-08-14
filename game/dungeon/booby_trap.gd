class_name BoobyTrap
extends Node2D

signal activated(trap: BoobyTrap, target: DungeonEntity, damage_hearts: int)

const DAMAGE_HEARTS: int = 1

var cell: Vector2i = Vector2i.ZERO
var is_activated: bool = false
var is_known: bool = false
var is_lit: bool = false


func setup(new_cell: Vector2i) -> void:
	cell = new_cell
	position = Vector2(
		(float(cell.x) + 0.5) * DungeonLevel.TILE_SIZE,
		(float(cell.y) + 0.5) * DungeonLevel.TILE_SIZE,
	)
	queue_redraw()


func activate(target: DungeonEntity) -> int:
	if is_activated or target == null or not is_instance_valid(target):
		return 0
	if target.health == null or target.health.is_depleted():
		return 0

	# Set the state before applying damage so a signal callback cannot trigger it twice.
	is_activated = true
	queue_redraw()
	var damage_dealt: int = target.take_damage(DAMAGE_HEARTS)
	activated.emit(self, target, damage_dealt)
	return damage_dealt


func trigger(target: DungeonEntity) -> int:
	return activate(target)


func set_explored_state(lit: bool, known: bool) -> void:
	is_lit = lit
	is_known = known
	visible = known
	modulate = Color.WHITE if lit else Color("#626b7b")
	queue_redraw()


func _ready() -> void:
	z_index = 1
	visible = false
	queue_redraw()


func _draw() -> void:
	var plate_color: Color = Color("#7d4d57") if not is_activated else Color("#3c414b")
	draw_circle(Vector2(1, 5), 10.0, Color(0.0, 0.0, 0.0, 0.3))
	draw_rect(Rect2(-10, -7, 20, 14), plate_color, true)
	draw_rect(Rect2(-10, -7, 20, 14), Color("#c77872") if not is_activated else Color("#68717d"), false, 2.0)

	if is_activated:
		draw_line(Vector2(-6, -4), Vector2(6, 4), Color("#aab3bd"), 2.0)
		draw_line(Vector2(6, -4), Vector2(-6, 4), Color("#aab3bd"), 2.0)
		return

	# The uncovered pressure plate has a small warning mark when it is visible.
	draw_line(Vector2(-4, 3), Vector2(0, -4), Color("#f0c76b"), 2.0)
	draw_line(Vector2(0, -4), Vector2(4, 3), Color("#f0c76b"), 2.0)
