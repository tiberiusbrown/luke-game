class_name HealingItemData
extends RefCounted

const MIN_HEALING_HEARTS: int = 1
const HEALING_ITEM_NAMES: Array[String] = [
	"Amber Potion",
	"Moonleaf Tonic",
	"Sunstone",
	"Crimson Draught",
	"Heartroot Poultice",
]
const HEALING_VALUES: Dictionary = {
	"Amber Potion": 2,
	"Moonleaf Tonic": 3,
	"Sunstone": 4,
	"Crimson Draught": 5,
	"Heartroot Poultice": 7,
}

var item_name: String
var healing_hearts: int


func _init(new_item_name: String = "Healing Item", new_healing_hearts: int = MIN_HEALING_HEARTS) -> void:
	item_name = new_item_name.strip_edges()
	if item_name.is_empty():
		item_name = "Healing Item"
	healing_hearts = maxi(new_healing_hearts, MIN_HEALING_HEARTS)


static func from_name(new_item_name: String) -> HealingItemData:
	var normalized_name: String = new_item_name.strip_edges()
	if not HEALING_VALUES.has(normalized_name):
		return null
	return HealingItemData.new(normalized_name, int(HEALING_VALUES[normalized_name]))


static func get_healing_hearts(new_item_name: String) -> int:
	var healing_item: HealingItemData = from_name(new_item_name)
	return healing_item.healing_hearts if healing_item != null else 0
