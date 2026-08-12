class_name DungeonVendor
extends Node2D

const VENDOR_NAME: String = "Rook the Broker"
const TRADE_CURRENCY: String = "Ancient Coin"
const VENDOR_ITEM_STOCK: Array[String] = [
	"Amber Potion",
	"Crystal Shard",
	"Moonleaf Tonic",
	"Sunstone",
	"Crimson Draught",
	"Heartroot Poultice",
]
const VENDOR_WEAPON_STOCK: Array[Dictionary] = [
	{"name": "Moonsteel Blade", "damage": 3},
	{"name": "Iron Mace", "damage": 2},
	{"name": "Shadow Dagger", "damage": 2},
	{"name": "Thunder Hammer", "damage": 3},
]

var cell: Vector2i = Vector2i.ZERO
var dungeon_level: DungeonLevel = null
var inventory: PlayerInventory = PlayerInventory.new()
var is_known: bool = false
var is_lit: bool = false


func _init() -> void:
	for item_name: String in VENDOR_ITEM_STOCK:
		inventory.add_item(item_name)
	for weapon_definition: Dictionary in VENDOR_WEAPON_STOCK:
		inventory.add_weapon(
			WeaponData.new(
				str(weapon_definition["name"]),
				int(weapon_definition["damage"]),
			)
		)


func _ready() -> void:
	z_index = 3
	visible = false
	queue_redraw()


func setup(new_dungeon_level: DungeonLevel, new_cell: Vector2i) -> void:
	dungeon_level = new_dungeon_level
	cell = new_cell
	if dungeon_level != null:
		position = dungeon_level.cell_to_world(cell)
	queue_redraw()


func get_display_name() -> String:
	return VENDOR_NAME


func get_interaction_title() -> String:
	return "ROOK'S EXCHANGE"


func get_stock_label() -> String:
	return "ROOK'S STOCK"


func get_trade_status() -> String:
	return "ONE ANCIENT COIN FOR ONE ITEM"


func set_explored_state(lit: bool, known: bool) -> void:
	is_lit = lit
	is_known = known
	visible = known
	modulate = Color.WHITE if lit else Color("#626b7b")
	queue_redraw()


func exchange(
	player_inventory: PlayerInventory,
	offered_entry: Dictionary,
	requested_entry: Dictionary,
) -> bool:
	if player_inventory == null:
		return false
	if not is_currency_entry(offered_entry):
		return false
	if not player_inventory.has_trade_entry(offered_entry):
		return false
	if not inventory.has_trade_entry(requested_entry):
		return false

	if not player_inventory.remove_trade_entry(offered_entry):
		return false
	if not inventory.remove_trade_entry(requested_entry):
		player_inventory.add_trade_entry(offered_entry)
		return false

	player_inventory.add_trade_entry(requested_entry)
	inventory.add_trade_entry(offered_entry)
	return true


static func is_currency_entry(entry: Dictionary) -> bool:
	var weapon_value: Variant = entry.get("weapon", null)
	return weapon_value == null and str(entry.get("item_name", "")).strip_edges() == TRADE_CURRENCY


func _draw() -> void:
	var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.32)
	_draw_shadow_ellipse(Vector2(2, 10), Vector2(11, 5), shadow_color)

	var cloak_color: Color = Color("#b8794f")
	var cloak_points: PackedVector2Array = PackedVector2Array([
		Vector2(-10, 10),
		Vector2(-8, -1),
		Vector2(-5, -7),
		Vector2(5, -7),
		Vector2(8, -1),
		Vector2(10, 10),
	])
	draw_colored_polygon(cloak_points, cloak_color.darkened(0.35))
	draw_polyline(cloak_points, cloak_color.lightened(0.15), 2.0)

	draw_circle(Vector2.ZERO, 7.0, Color("#d49b6a"))
	draw_colored_polygon(
		PackedVector2Array([
			Vector2(-9, -4),
			Vector2(0, -11),
			Vector2(9, -4),
			Vector2(6, -1),
			Vector2(-6, -1),
		]),
		Color("#6c4a55"),
	)
	draw_circle(Vector2(-2, -1), 1.0, Color("#f5d39e"))
	draw_circle(Vector2(3, -1), 1.0, Color("#f5d39e"))
	draw_line(Vector2(8, 3), Vector2(13, 12), Color("#d6a85f"), 2.0)
	draw_circle(Vector2(13, 12), 2.0, Color("#d6a85f"))


func _draw_shadow_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for point_index: int in range(20):
		var angle: float = TAU * float(point_index) / 20.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
