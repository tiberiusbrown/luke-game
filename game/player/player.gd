class_name DungeonPlayer
extends CharacterBody2D

const MOVE_SPEED: float = 170.0
const MAX_COLLISION_STEP: float = 2.0
const PLAYER_RADIUS: float = 9.0

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
	_move_with_collision_slide(velocity * delta)

	velocity = Vector2.ZERO


func _move_with_collision_slide(motion: Vector2) -> void:
	var motion_length: float = motion.length()
	if is_zero_approx(motion_length):
		return

	var step_count: int = maxi(1, ceili(motion_length / MAX_COLLISION_STEP))
	var step_motion: Vector2 = motion / float(step_count)
	for _step: int in range(step_count):
		position = _resolve_motion_step(position, step_motion)


func _resolve_motion_step(start_position: Vector2, motion: Vector2) -> Vector2:
	var requested_position: Vector2 = start_position + motion
	if dungeon_level.can_stand_at(requested_position):
		return requested_position

	# Trying both orders matters at corners. Moving along the open side first
	# can make the other component valid on the same frame, producing a smooth
	# slide instead of stopping at the corner.
	var horizontal_first: Vector2 = _resolve_axis_order(
		start_position,
		motion,
		true
	)
	var vertical_first: Vector2 = _resolve_axis_order(
		start_position,
		motion,
		false
	)
	var horizontal_progress: float = (horizontal_first - start_position).dot(motion)
	var vertical_progress: float = (vertical_first - start_position).dot(motion)
	if horizontal_progress >= vertical_progress:
		if horizontal_first != start_position:
			return horizontal_first
	else:
		if vertical_first != start_position:
			return vertical_first

	# A pure horizontal or vertical input can still be blocked by a corner
	# even though one side of that corner is open. Only slide when the player's
	# center is already past the obstacle's corner edge in that direction.
	return _try_corner_slide(start_position, motion)


func _try_corner_slide(start_position: Vector2, motion: Vector2) -> Vector2:
	var slide_distance: float = motion.length()
	if is_zero_approx(slide_distance):
		return start_position

	var slide_direction: Vector2 = _get_corner_slide_direction(start_position, motion)
	if slide_direction != Vector2.ZERO:
		var slide_position: Vector2 = start_position + slide_direction * slide_distance
		if dungeon_level.can_stand_at(slide_position):
			return slide_position

	return start_position


func _get_corner_slide_direction(start_position: Vector2, motion: Vector2) -> Vector2:
	var requested_position: Vector2 = start_position + motion
	if not is_zero_approx(motion.x) and is_zero_approx(motion.y):
		var leading_x: float = signf(motion.x) * PLAYER_RADIUS
		var top_cell: Vector2i = dungeon_level.world_to_cell(
			requested_position + Vector2(leading_x, -PLAYER_RADIUS)
		)
		var bottom_cell: Vector2i = dungeon_level.world_to_cell(
			requested_position + Vector2(leading_x, PLAYER_RADIUS)
		)
		var top_blocked: bool = not dungeon_level.is_walkable(top_cell)
		var bottom_blocked: bool = not dungeon_level.is_walkable(bottom_cell)
		if top_blocked == bottom_blocked:
			return Vector2.ZERO
		if top_blocked:
			var lower_corner_edge: float = float((top_cell.y + 1) * DungeonLevel.TILE_SIZE)
			if start_position.y > lower_corner_edge:
				return Vector2(0.0, 1.0)
		else:
			var upper_corner_edge: float = float(bottom_cell.y * DungeonLevel.TILE_SIZE)
			if start_position.y < upper_corner_edge:
				return Vector2(0.0, -1.0)
	elif not is_zero_approx(motion.y) and is_zero_approx(motion.x):
		var leading_y: float = signf(motion.y) * PLAYER_RADIUS
		var left_cell: Vector2i = dungeon_level.world_to_cell(
			requested_position + Vector2(-PLAYER_RADIUS, leading_y)
		)
		var right_cell: Vector2i = dungeon_level.world_to_cell(
			requested_position + Vector2(PLAYER_RADIUS, leading_y)
		)
		var left_blocked: bool = not dungeon_level.is_walkable(left_cell)
		var right_blocked: bool = not dungeon_level.is_walkable(right_cell)
		if left_blocked == right_blocked:
			return Vector2.ZERO
		if left_blocked:
			var right_corner_edge: float = float((left_cell.x + 1) * DungeonLevel.TILE_SIZE)
			if start_position.x > right_corner_edge:
				return Vector2(1.0, 0.0)
		else:
			var left_corner_edge: float = float(right_cell.x * DungeonLevel.TILE_SIZE)
			if start_position.x < left_corner_edge:
				return Vector2(-1.0, 0.0)

	return Vector2.ZERO


func _resolve_axis_order(
		start_position: Vector2,
		motion: Vector2,
		horizontal_first: bool
) -> Vector2:
	var resolved_position: Vector2 = start_position
	if horizontal_first:
		resolved_position = _try_axis_motion(resolved_position, Vector2(motion.x, 0.0))
		resolved_position = _try_axis_motion(resolved_position, Vector2(0.0, motion.y))
	else:
		resolved_position = _try_axis_motion(resolved_position, Vector2(0.0, motion.y))
		resolved_position = _try_axis_motion(resolved_position, Vector2(motion.x, 0.0))
	return resolved_position


func _try_axis_motion(start_position: Vector2, axis_motion: Vector2) -> Vector2:
	var candidate_position: Vector2 = start_position + axis_motion
	if dungeon_level.can_stand_at(candidate_position):
		return candidate_position
	return start_position


func _draw() -> void:
	draw_circle(Vector2(2, 4), 11.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(Vector2.ZERO, 10.0, Color("#e7eef4"))
	draw_circle(Vector2.ZERO, 8.0, Color("#68a7d8"))
	draw_circle(Vector2(-3, -2), 1.5, Color("#f5f7fa"))
	draw_circle(Vector2(3, -2), 1.5, Color("#f5f7fa"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("#b9d4e8"), 2.0)
