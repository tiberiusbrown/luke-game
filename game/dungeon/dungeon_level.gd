class_name DungeonLevel
extends Node2D

signal dungeon_generated(start_cell: Vector2i, exit_cell: Vector2i)

const GRID_WIDTH: int = 25
const GRID_HEIGHT: int = 17
const TILE_SIZE: int = 32
const WALL: int = 0
const FLOOR: int = 1

var tiles: Array = []
var start_cell: Vector2i = Vector2i.ZERO
var exit_cell: Vector2i = Vector2i.ZERO

var _random: RandomNumberGenerator = RandomNumberGenerator.new()


func _enter_tree() -> void:
	generate()


func generate() -> void:
	_random.randomize()
	tiles.clear()

	for y in range(GRID_HEIGHT):
		var row: Array[int] = []
		for x in range(GRID_WIDTH):
			row.append(WALL)
		tiles.append(row)

	var rooms: Array[Rect2i] = []
	for room_index in range(8):
		var room_width: int = _random.randi_range(3, 6)
		var room_height: int = _random.randi_range(3, 5)
		var room_x: int = _random.randi_range(1, GRID_WIDTH - room_width - 1)
		var room_y: int = _random.randi_range(1, GRID_HEIGHT - room_height - 1)
		var room: Rect2i = Rect2i(room_x, room_y, room_width, room_height)
		rooms.append(room)
		_carve_room(room)

		if room_index > 0:
			var previous_center: Vector2i = rooms[room_index - 1].get_center()
			var current_center: Vector2i = room.get_center()
			_carve_corridor(previous_center, current_center)

	start_cell = rooms[0].get_center()
	exit_cell = rooms[rooms.size() - 1].get_center()
	queue_redraw()
	dungeon_generated.emit(start_cell, exit_cell)


func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.x >= GRID_WIDTH or cell.y < 0 or cell.y >= GRID_HEIGHT:
		return false
	return tiles[cell.y][cell.x] == FLOOR


func can_stand_at(world_position: Vector2) -> bool:
	const PLAYER_RADIUS: float = 9.0
	var corners: Array[Vector2] = [
		world_position + Vector2(-PLAYER_RADIUS, -PLAYER_RADIUS),
		world_position + Vector2(PLAYER_RADIUS, -PLAYER_RADIUS),
		world_position + Vector2(-PLAYER_RADIUS, PLAYER_RADIUS),
		world_position + Vector2(PLAYER_RADIUS, PLAYER_RADIUS),
	]
	for corner: Vector2 in corners:
		if not is_walkable(world_to_cell(corner)):
			return false
	return true


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(
		(float(cell.x) + 0.5) * TILE_SIZE,
		(float(cell.y) + 0.5) * TILE_SIZE
	)


func world_to_cell(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_position.x / TILE_SIZE),
		floori(world_position.y / TILE_SIZE)
	)


func get_start_cell() -> Vector2i:
	return start_cell


func get_exit_cell() -> Vector2i:
	return exit_cell


func _carve_room(room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			tiles[y][x] = FLOOR


func _carve_corridor(from_cell: Vector2i, to_cell: Vector2i) -> void:
	var horizontal_first: bool = _random.randi_range(0, 1) == 0
	if horizontal_first:
		_carve_horizontal(from_cell.x, to_cell.x, from_cell.y)
		_carve_vertical(from_cell.y, to_cell.y, to_cell.x)
	else:
		_carve_vertical(from_cell.y, to_cell.y, from_cell.x)
		_carve_horizontal(from_cell.x, to_cell.x, to_cell.y)


func _carve_horizontal(from_x: int, to_x: int, y: int) -> void:
	var start_x: int = mini(from_x, to_x)
	var end_x: int = maxi(from_x, to_x)
	for x in range(start_x, end_x + 1):
		tiles[y][x] = FLOOR


func _carve_vertical(from_y: int, to_y: int, x: int) -> void:
	var start_y: int = mini(from_y, to_y)
	var end_y: int = maxi(from_y, to_y)
	for y in range(start_y, end_y + 1):
		tiles[y][x] = FLOOR


func _draw() -> void:
	var map_size: Vector2 = Vector2(GRID_WIDTH * TILE_SIZE, GRID_HEIGHT * TILE_SIZE)
	draw_rect(Rect2(Vector2.ZERO, map_size), Color("#0b0e15"))

	for y in range(GRID_HEIGHT):
		for x in range(GRID_WIDTH):
			var tile_rect: Rect2 = Rect2(
				Vector2(x * TILE_SIZE, y * TILE_SIZE),
				Vector2(TILE_SIZE, TILE_SIZE)
			)
			var is_floor: bool = tiles.size() == GRID_HEIGHT and tiles[y][x] == FLOOR
			if is_floor:
				draw_rect(tile_rect, Color("#252b39"))
				draw_rect(tile_rect.grow(-1.0), Color("#303849"))
			else:
				draw_rect(tile_rect.grow(-1.0), Color("#111621"))


	_draw_marker(start_cell, Color("#4bc6a7"), false)
	_draw_marker(exit_cell, Color("#d6a85f"), true)


func _draw_marker(cell: Vector2i, color: Color, is_exit: bool) -> void:
	var marker_center: Vector2 = cell_to_world(cell)
	if is_exit:
		var points: PackedVector2Array = PackedVector2Array([
			marker_center + Vector2(0, -9),
			marker_center + Vector2(9, 0),
			marker_center + Vector2(0, 9),
			marker_center + Vector2(-9, 0),
		])
		draw_colored_polygon(points, color.darkened(0.35))
		draw_polyline(points, color, 2.0)
	else:
		draw_circle(marker_center, 8.0, color.darkened(0.35))
		draw_arc(marker_center, 8.0, 0.0, TAU, 20, color, 2.0)
