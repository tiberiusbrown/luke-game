class_name HeartHealthBar
extends Control

const HEART_WIDTH: float = 18.0
const HEART_HEIGHT: float = 18.0
const HEART_SPACING: float = 2.0

var _health: HeartHealth = null


func bind_health(new_health: HeartHealth) -> void:
	if _health != null and _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.disconnect(_on_health_changed)

	_health = new_health
	if _health != null:
		_health.health_changed.connect(_on_health_changed)
		custom_minimum_size = Vector2(_get_bar_width(_health.max_hearts), HEART_HEIGHT)
	queue_redraw()


func _on_health_changed(_current_hearts: int, max_hearts: int) -> void:
	custom_minimum_size = Vector2(_get_bar_width(max_hearts), HEART_HEIGHT)
	queue_redraw()


func _draw() -> void:
	if _health == null:
		return

	for heart_index: int in range(_health.max_hearts):
		var heart_position: Vector2 = Vector2(
			heart_index * (HEART_WIDTH + HEART_SPACING) + HEART_WIDTH * 0.5,
			HEART_HEIGHT * 0.5,
		)
		_draw_heart(heart_position, heart_index < _health.current_hearts)


func _draw_heart(center: Vector2, is_filled: bool) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, 9),
		center + Vector2(-8, 1),
		center + Vector2(-9, -3),
		center + Vector2(-8, -7),
		center + Vector2(-5, -9),
		center + Vector2(-2, -9),
		center + Vector2(0, -6),
		center + Vector2(2, -9),
		center + Vector2(5, -9),
		center + Vector2(8, -7),
		center + Vector2(9, -3),
		center + Vector2(8, 1),
	])
	var fill_color: Color = Color("#e85f70") if is_filled else Color("#293244")
	var outline_color: Color = Color("#ff9aa7") if is_filled else Color("#566179")
	draw_colored_polygon(points, fill_color)
	draw_polyline(points, outline_color, 1.25, true)
	if is_filled:
		draw_circle(center + Vector2(-4, -4), 1.4, Color(1.0, 0.86, 0.88, 0.8))


func _get_bar_width(heart_count: int) -> float:
	if heart_count <= 0:
		return 0.0
	return heart_count * HEART_WIDTH + (heart_count - 1) * HEART_SPACING
