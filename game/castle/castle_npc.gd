class_name DungeonCastleNpc
extends Node2D

var cell: Vector2i = Vector2i.ZERO
var npc_name: String = "Castle Resident"
var dialogue: String = "Welcome to the castle."
var dungeon_level: DungeonLevel = null
var is_known: bool = false
var is_lit: bool = false


func _ready() -> void:
	z_index = 3
	visible = false
	queue_redraw()


func setup(
	new_dungeon_level: DungeonLevel,
	new_cell: Vector2i,
	new_npc_name: String,
	new_dialogue: String,
) -> void:
	dungeon_level = new_dungeon_level
	cell = new_cell
	npc_name = new_npc_name
	dialogue = new_dialogue
	if dungeon_level != null:
		position = dungeon_level.cell_to_world(cell)
	queue_redraw()


func get_display_name() -> String:
	return npc_name


func get_dialogue() -> String:
	return dialogue


func set_explored_state(lit: bool, known: bool) -> void:
	is_lit = lit
	is_known = known
	visible = known
	modulate = Color.WHITE if lit else Color("#626b7b")
	queue_redraw()


func _draw() -> void:
	draw_circle(Vector2(2, 9), 11.0, Color(0.0, 0.0, 0.0, 0.30))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-9, 11),
			Vector2(-8, -1),
			Vector2(-5, -7),
			Vector2(5, -7),
			Vector2(8, -1),
			Vector2(9, 11),
		]),
		Color("#4f6f68"),
	)
	draw_circle(Vector2.ZERO, 7.0, Color("#d49b6a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-9, -4),
			Vector2(0, -12),
			Vector2(9, -4),
			Vector2(6, -1),
			Vector2(-6, -1),
		]),
		Color("#c59b58"),
	)
	draw_circle(Vector2(-2, -1), 1.0, Color("#f5d39e"))
	draw_circle(Vector2(3, -1), 1.0, Color("#f5d39e"))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 24, Color("#e4c16d"), 1.5)
