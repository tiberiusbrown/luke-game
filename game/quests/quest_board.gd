class_name DungeonQuestBoard
extends Node2D

signal quest_changed
signal quest_message(message: String)

var cell: Vector2i = Vector2i.ZERO
var dungeon_level: DungeonLevel = null
var is_known: bool = false
var is_lit: bool = false
var selected_index: int = 0
var active_index: int = -1
var progress: int = 0
var difficulty: DungeonLevel.Difficulty = DungeonLevel.Difficulty.NORMAL

var _quests: Array[Dictionary] = [
	{
		"id": "castle_watch",
		"title": "Castle Watch",
		"description": "Defeat 3 dungeon enemies.",
		"kind": "defeat",
		"target": 3,
		"reward": "5 Ancient Coins",
		"reward_kind": "coins",
		"reward_amount": 5,
	},
	{
		"id": "coin_run",
		"title": "Coin Run",
		"description": "Collect 3 Ancient Coins from the deep.",
		"kind": "collect",
		"target": 3,
		"reward": "Amber Potion",
		"reward_kind": "item",
		"reward_amount": 1,
	},
	{
		"id": "deep_hunter",
		"title": "Deep Hunter",
		"description": "Defeat 6 dungeon enemies.",
		"kind": "defeat",
		"target": 6,
		"reward": "Knight's Longsword",
		"reward_kind": "weapon",
		"reward_amount": 3,
	},
]


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


func configure_for_difficulty(new_difficulty: DungeonLevel.Difficulty) -> void:
	difficulty = new_difficulty
	_quests = _build_quests(new_difficulty)
	selected_index = 0
	active_index = -1
	progress = 0
	quest_changed.emit()


func get_difficulty_name() -> String:
	match difficulty:
		DungeonLevel.Difficulty.EASY:
			return "EASY"
		DungeonLevel.Difficulty.HARD:
			return "HARD"
		_:
			return "NORMAL"


func get_quests() -> Array[Dictionary]:
	return _quests.duplicate(true)


func get_selected_quest() -> Dictionary:
	if _quests.is_empty():
		return {}
	return _quests[selected_index]


func get_active_quest() -> Dictionary:
	if active_index < 0 or active_index >= _quests.size():
		return {}
	return _quests[active_index]


func get_progress() -> int:
	return progress


func is_quest_completed(index: int) -> bool:
	# Quests are repeatable. This method remains available for the panel API.
	return false


func is_active(index: int) -> bool:
	return active_index == index


func is_active_complete() -> bool:
	return active_index >= 0 and progress >= int(get_active_quest()["target"])


func select_quest(direction: int) -> void:
	if _quests.is_empty() or active_index >= 0:
		return
	selected_index = posmod(selected_index + direction, _quests.size())
	quest_changed.emit()


func activate_selected_quest() -> bool:
	if active_index >= 0:
		if is_active_complete():
			quest_message.emit("QUEST COMPLETE — PRESS ENTER TO CLAIM %s" % str(get_active_quest()["reward"]).to_upper())
		else:
			quest_message.emit("QUEST IN PROGRESS — %d/%d" % [progress, int(get_active_quest()["target"])])
		return false
	active_index = selected_index
	progress = 0
	quest_message.emit("QUEST ACCEPTED: %s" % str(get_active_quest()["title"]).to_upper())
	quest_changed.emit()
	return true


func claim_active_quest(player_inventory: PlayerInventory) -> bool:
	if active_index < 0:
		quest_message.emit("SELECT AND ACCEPT A QUEST FIRST")
		return false
	if not is_active_complete():
		quest_message.emit("QUEST IN PROGRESS — %d/%d" % [progress, int(get_active_quest()["target"])])
		return false
	if player_inventory == null:
		return false

	var quest: Dictionary = get_active_quest()
	var reward_kind: String = str(quest["reward_kind"])
	if reward_kind == "coins":
		for _coin_index: int in range(int(quest["reward_amount"])):
			player_inventory.add_item("Ancient Coin")
	elif reward_kind == "item":
		player_inventory.add_item(str(quest["reward"]))
	elif reward_kind == "weapon":
		player_inventory.add_weapon(WeaponData.new(str(quest["reward"]), int(quest["reward_amount"])))

	var claimed_reward: String = str(quest["reward"])
	active_index = -1
	progress = 0
	selected_index = mini(selected_index + 1, _quests.size() - 1)
	quest_message.emit("REWARD CLAIMED: %s" % claimed_reward.to_upper())
	quest_changed.emit()
	return true


func _build_quests(new_difficulty: DungeonLevel.Difficulty) -> Array[Dictionary]:
	match new_difficulty:
		DungeonLevel.Difficulty.EASY:
			return [
				_make_quest("easy_watch", "Castle Watch", "Defeat 2 dungeon enemies.", "defeat", 2, "4 Ancient Coins", "coins", 4),
				_make_quest("easy_coin_run", "Coin Run", "Collect 2 Ancient Coins from the deep.", "collect", 2, "Amber Potion", "item", 1),
				_make_quest("easy_hunter", "Deep Hunter", "Defeat 4 dungeon enemies.", "defeat", 4, "Rusty Sword", "weapon", 2),
			]
		DungeonLevel.Difficulty.HARD:
			return [
				_make_quest("hard_watch", "Castle Watch", "Defeat 5 dungeon enemies.", "defeat", 5, "8 Ancient Coins", "coins", 8),
				_make_quest("hard_coin_run", "Coin Run", "Collect 5 Ancient Coins from the deep.", "collect", 5, "Heartroot Poultice", "item", 1),
				_make_quest("hard_hunter", "Deep Hunter", "Defeat 10 dungeon enemies.", "defeat", 10, "Knight's Longsword", "weapon", 3),
			]
		_:
			return [
				_make_quest("castle_watch", "Castle Watch", "Defeat 3 dungeon enemies.", "defeat", 3, "5 Ancient Coins", "coins", 5),
				_make_quest("coin_run", "Coin Run", "Collect 3 Ancient Coins from the deep.", "collect", 3, "Amber Potion", "item", 1),
				_make_quest("deep_hunter", "Deep Hunter", "Defeat 6 dungeon enemies.", "defeat", 6, "Knight's Longsword", "weapon", 3),
			]


func _make_quest(
		quest_id: String,
		quest_title: String,
		quest_description: String,
		quest_kind: String,
		quest_target: int,
		quest_reward: String,
		quest_reward_kind: String,
		quest_reward_amount: int,
) -> Dictionary:
	return {
		"id": quest_id,
		"title": quest_title,
		"description": quest_description,
		"kind": quest_kind,
		"target": quest_target,
		"reward": quest_reward,
		"reward_kind": quest_reward_kind,
		"reward_amount": quest_reward_amount,
	}


func notify_enemy_defeated(_enemy_name: String) -> void:
	_advance_if_kind("defeat")


func notify_item_collected(item_name: String) -> void:
	if item_name == "Ancient Coin":
		_advance_if_kind("collect")


func set_explored_state(lit: bool, known: bool) -> void:
	is_lit = lit
	is_known = known
	visible = known
	modulate = Color.WHITE if lit else Color("#626b7b")
	queue_redraw()


func _advance_if_kind(kind: String) -> void:
	if active_index < 0:
		return
	var quest: Dictionary = get_active_quest()
	if str(quest["kind"]) != kind or is_active_complete():
		return
	progress = mini(progress + 1, int(quest["target"]))
	if is_active_complete():
		quest_message.emit("QUEST COMPLETE: RETURN TO THE BOARD TO CLAIM YOUR REWARD")
	quest_changed.emit()


func _draw() -> void:
	draw_circle(Vector2(2, 10), 12.0, Color(0.0, 0.0, 0.0, 0.35))
	draw_rect(Rect2(-10, -12, 20, 24), Color("#704d38"), true)
	draw_rect(Rect2(-9, -11, 18, 22), Color("#b8794f"), false, 2.0)
	draw_line(Vector2(-6, -4), Vector2(6, -4), Color("#f0d49a"), 2.0)
	draw_line(Vector2(-6, 1), Vector2(5, 1), Color("#f0d49a"), 2.0)
	draw_line(Vector2(-6, 6), Vector2(3, 6), Color("#f0d49a"), 2.0)
