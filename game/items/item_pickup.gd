class_name ItemPickup
extends Node2D

@export var item_name: String = "Ancient Coin"

var cell: Vector2i = Vector2i.ZERO
var weapon_data: WeaponData = null
var healing_item_data: HealingItemData = null
var is_known: bool = false
var is_lit: bool = false


func setup(
	new_item_name: String,
	new_cell: Vector2i,
	new_weapon_data: WeaponData = null,
	new_healing_item_data: HealingItemData = null,
) -> void:
	item_name = new_item_name
	cell = new_cell
	weapon_data = new_weapon_data
	healing_item_data = new_healing_item_data
	position = Vector2(
		(float(cell.x) + 0.5) * DungeonLevel.TILE_SIZE,
		(float(cell.y) + 0.5) * DungeonLevel.TILE_SIZE
	)
	queue_redraw()


func _ready() -> void:
	z_index = 1
	visible = false
	queue_redraw()


func set_explored_state(lit: bool, known: bool) -> void:
	is_lit = lit
	is_known = known
	visible = known
	modulate = Color.WHITE if lit else Color("#626b7b")
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

	if weapon_data != null:
		_draw_weapon(item_color)
	elif healing_item_data != null:
		draw_circle(Vector2.ZERO, 3.0, item_color.lightened(0.35))
		draw_line(Vector2(-4, 0), Vector2(4, 0), item_color.lightened(0.45), 1.5)
		draw_line(Vector2(0, -4), Vector2(0, 4), item_color.lightened(0.45), 1.5)
	elif item_name == "Ancient Coin":
		draw_circle(Vector2.ZERO, 3.0, item_color.lightened(0.35))
		draw_line(Vector2(-2, 0), Vector2(2, 0), item_color.darkened(0.2), 1.5)
	elif item_name == DungeonLevel.BOSS_PRISON_KEY:
		draw_circle(Vector2(-2, -2), 2.5, item_color.lightened(0.35))
		draw_line(Vector2(0, 0), Vector2(6, 6), item_color.lightened(0.25), 2.0)
		draw_line(Vector2(3, 4), Vector2(6, 2), item_color.darkened(0.2), 1.5)
	elif item_name == DungeonLevel.SKULL_ITEM_NAME:
		draw_circle(Vector2.ZERO, 4.5, item_color.lightened(0.3))
		draw_circle(Vector2(-2, -1), 1.2, item_color.darkened(0.45))
		draw_circle(Vector2(2, -1), 1.2, item_color.darkened(0.45))
		draw_rect(Rect2(-2.5, 3.0, 5.0, 2.5), item_color.lightened(0.15))
	else:
		draw_line(Vector2(-3, -3), Vector2(3, 3), item_color.lightened(0.35), 2.0)
		draw_line(Vector2(3, -3), Vector2(-3, 3), item_color.lightened(0.35), 2.0)


func _get_item_color() -> Color:
	if weapon_data != null:
		return Color("#c7cedc") if weapon_data.attack_damage == 2 else Color("#d08d5c")
	match item_name:
		"Amber Potion":
			return Color("#d87853")
		"Moonleaf Tonic":
			return Color("#72b58b")
		"Sunstone":
			return Color("#e2b45b")
		"Crimson Draught":
			return Color("#bd536b")
		"Heartroot Poultice":
			return Color("#a97054")
		"Ancient Coin":
			return Color("#d6a85f")
		"Crystal Shard":
			return Color("#68a7d8")
		DungeonLevel.BOSS_PRISON_KEY:
			return Color("#e85f70")
		DungeonLevel.SKULL_ITEM_NAME:
			return Color("#d7d9d2")
		_:
			return Color("#a68bd4")


func _draw_weapon(item_color: Color) -> void:
	draw_line(Vector2(-6, 6), Vector2(6, -6), item_color.lightened(0.25), 3.0)
	draw_line(Vector2(-8, 3), Vector2(-3, 8), item_color.darkened(0.15), 2.0)
	draw_line(Vector2(-5, 1), Vector2(-1, 5), item_color.lightened(0.1), 2.0)
