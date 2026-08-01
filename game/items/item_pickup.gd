class_name ItemPickup
extends Node2D

@export var item_name: String = "Ancient Coin"

var cell: Vector2i = Vector2i.ZERO


func setup(new_item_name: String, new_cell: Vector2i) -> void:
	item_name = new_item_name
	cell = new_cell
	position = Vector2(
		(float(cell.x) + 0.5) * DungeonLevel.TILE_SIZE,
		(float(cell.y) + 0.5) * DungeonLevel.TILE_SIZE
	)
	queue_redraw()


func _ready() -> void:
	z_index = 1
	queue_redraw()


func _draw() -> void:
	var item_color: Color = _get_item_color()
	draw_circle(Vector2(1, 4), 9.0, Color(0.0, 0.0, 0.0, 0.3))

	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -10),
		Vector2(8, 0),
		Vector2(0, 10),
		Vector2(-8, 0),
	])
	draw_colored_polygon(points, item_color.darkened(0.25))
	draw_polyline(points, item_color.lightened(0.2), 2.0)

	if item_name == "Amber Potion":
		draw_circle(Vector2.ZERO, 3.0, item_color.lightened(0.35))
	elif item_name == "Ancient Coin":
		draw_circle(Vector2.ZERO, 3.0, item_color.lightened(0.35))
		draw_line(Vector2(-2, 0), Vector2(2, 0), item_color.darkened(0.2), 1.5)
	else:
		draw_line(Vector2(-3, -3), Vector2(3, 3), item_color.lightened(0.35), 2.0)
		draw_line(Vector2(3, -3), Vector2(-3, 3), item_color.lightened(0.35), 2.0)


func _get_item_color() -> Color:
	match item_name:
		"Amber Potion":
			return Color("#d87853")
		"Ancient Coin":
			return Color("#d6a85f")
		"Crystal Shard":
			return Color("#68a7d8")
		_:
			return Color("#a68bd4")
