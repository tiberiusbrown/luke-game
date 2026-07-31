class_name DungeonPlayer
extends CharacterBody2D

const MOVE_SPEED: float = 170.0

var dungeon_level: DungeonLevel


func _ready() -> void:
	dungeon_level = get_parent() as DungeonLevel
	position = dungeon_level.cell_to_world(dungeon_level.get_start_cell())
	queue_redraw()


func _physics_process(delta: float) -> void:
	var horizontal_input: float = 0.0
	var vertical_input: float = 0.0
	if Input.is_key_pressed(KEY_LEFT):
		horizontal_input -= 1.0
	if Input.is_key_pressed(KEY_RIGHT):
		horizontal_input += 1.0
	if Input.is_key_pressed(KEY_UP):
		vertical_input -= 1.0
	if Input.is_key_pressed(KEY_DOWN):
		vertical_input += 1.0
	var input_direction: Vector2 = Vector2(horizontal_input, vertical_input).normalized()
	velocity = input_direction * MOVE_SPEED

	var next_x: Vector2 = position + Vector2(velocity.x * delta, 0.0)
	if dungeon_level.can_stand_at(next_x):
		position.x = next_x.x

	var next_y: Vector2 = position + Vector2(0.0, velocity.y * delta)
	if dungeon_level.can_stand_at(next_y):
		position.y = next_y.y

	velocity = Vector2.ZERO


func _draw() -> void:
	draw_circle(Vector2(2, 4), 11.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(Vector2.ZERO, 10.0, Color("#e7eef4"))
	draw_circle(Vector2.ZERO, 8.0, Color("#68a7d8"))
	draw_circle(Vector2(-3, -2), 1.5, Color("#f5f7fa"))
	draw_circle(Vector2(3, -2), 1.5, Color("#f5f7fa"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("#b9d4e8"), 2.0)
