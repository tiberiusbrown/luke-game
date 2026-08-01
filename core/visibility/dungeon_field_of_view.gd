class_name DungeonFieldOfView
extends RefCounted

var _map_width: int
var _map_height: int
var _visible_cells: Dictionary = {}


func _init(map_width: int, map_height: int) -> void:
	_map_width = map_width
	_map_height = map_height


func compute(origin: Vector2i, radius: int, is_opaque: Callable) -> Array[Vector2i]:
	_visible_cells.clear()
	if radius < 0 or not _is_in_bounds(origin):
		return []

	_mark_visible(origin)
	var octants: Array[Array] = [
		[1, 0, 0, 1],
		[0, 1, 1, 0],
		[-1, 0, 0, 1],
		[0, -1, 1, 0],
		[-1, 0, 0, -1],
		[0, -1, -1, 0],
		[1, 0, 0, -1],
		[0, 1, -1, 0],
	]
	for octant: Array in octants:
		_cast_light(
			origin,
			1,
			1.0,
			0.0,
			radius,
			octant[0],
			octant[1],
			octant[2],
			octant[3],
			is_opaque,
		)

	var result: Array[Vector2i] = []
	for cell: Vector2i in _visible_cells.keys():
		result.append(cell)
	return result


func _cast_light(
	origin: Vector2i,
	row: int,
	start_slope: float,
	end_slope: float,
	radius: int,
	transform_xx: int,
	transform_xy: int,
	transform_yx: int,
	transform_yy: int,
	is_opaque: Callable,
) -> void:
	if start_slope < end_slope:
		return

	var new_start_slope: float = start_slope
	var radius_squared: int = radius * radius
	for distance: int in range(row, radius + 1):
		var blocked: bool = false
		var delta_y: int = -distance
		for delta_x: int in range(-distance, 1):
			var current_cell: Vector2i = Vector2i(
				origin.x + delta_x * transform_xx + delta_y * transform_xy,
				origin.y + delta_x * transform_yx + delta_y * transform_yy,
			)
			var left_slope: float = (float(delta_x) - 0.5) / (float(delta_y) + 0.5)
			var right_slope: float = (float(delta_x) + 0.5) / (float(delta_y) - 0.5)

			if start_slope < right_slope:
				continue
			if end_slope > left_slope:
				break

			if delta_x * delta_x + delta_y * delta_y <= radius_squared:
				_mark_visible(current_cell)

			var cell_is_opaque: bool = bool(is_opaque.call(current_cell))
			if blocked:
				if cell_is_opaque:
					new_start_slope = right_slope
					continue
				blocked = false
				start_slope = new_start_slope
			elif cell_is_opaque and distance < radius:
				blocked = true
				_cast_light(
					origin,
					distance + 1,
					start_slope,
					left_slope,
					radius,
					transform_xx,
					transform_xy,
					transform_yx,
					transform_yy,
					is_opaque,
				)
				new_start_slope = right_slope

		if blocked:
			break


func _mark_visible(cell: Vector2i) -> void:
	if _is_in_bounds(cell):
		_visible_cells[cell] = true


func _is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < _map_width and cell.y >= 0 and cell.y < _map_height
