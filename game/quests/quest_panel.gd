class_name QuestPanel
extends Panel

@onready var quest_list_label: Label = %QuestListLabel
@onready var quest_detail_label: Label = %QuestDetailLabel
@onready var quest_status_label: Label = %QuestStatusLabel
@onready var title_label: Label = $TitleLabel

var _board: DungeonQuestBoard = null
var _player_inventory: PlayerInventory = null


func show_board(board: DungeonQuestBoard, player_inventory: PlayerInventory) -> void:
	if _board != null and _board.quest_changed.is_connected(_on_board_changed):
		_board.quest_changed.disconnect(_on_board_changed)
	if _board != null and _board.quest_message.is_connected(_on_quest_message):
		_board.quest_message.disconnect(_on_quest_message)
	_board = board
	_player_inventory = player_inventory
	if _board != null:
		_board.quest_changed.connect(_on_board_changed)
		_board.quest_message.connect(_on_quest_message)
	visible = true
	title_label.text = "QUEST BOARD — %s" % board.get_difficulty_name()
	refresh()


func handle_key(key_event: InputEventKey) -> bool:
	if not key_event.pressed or key_event.echo:
		return true
	if _is_key(key_event, KEY_ESCAPE):
		visible = false
		return true
	if _board == null:
		return true
	if _is_key(key_event, KEY_UP):
		_board.select_quest(-1)
		return true
	if _is_key(key_event, KEY_DOWN):
		_board.select_quest(1)
		return true
	if _is_key(key_event, KEY_ENTER) or _is_key(key_event, KEY_KP_ENTER):
		if _board.is_active_complete():
			_board.claim_active_quest(_player_inventory)
		else:
			_board.activate_selected_quest()
		return true
	return true


func refresh() -> void:
	if _board == null:
		return
	var quests: Array[Dictionary] = _board.get_quests()
	var lines: PackedStringArray = PackedStringArray()
	for index: int in range(quests.size()):
		var quest: Dictionary = quests[index]
		var marker: String = ">" if index == _board.selected_index else " "
		var state: String = "CLAIMED" if _board.is_quest_completed(index) else "AVAILABLE"
		if _board.is_active(index):
			state = "ACTIVE"
		lines.append("%s %s  [%s]" % [marker, str(quest["title"]).to_upper(), state])
	quest_list_label.text = "\n".join(lines)

	var selected: Dictionary = _board.get_selected_quest()
	if selected.is_empty():
		quest_detail_label.text = "NO QUESTS AVAILABLE"
	else:
		quest_detail_label.text = "%s\n\n%s\n\nREWARD: %s" % [
			str(selected["title"]).to_upper(),
			str(selected["description"]),
			str(selected["reward"]),
		]
	if _board.active_index >= 0:
		var active: Dictionary = _board.get_active_quest()
		quest_status_label.text = "ACTIVE: %s  %d/%d\nENTER %s" % [
			str(active["title"]).to_upper(),
			_board.get_progress(),
			int(active["target"]),
			"TO CLAIM REWARD" if _board.is_active_complete() else "TO CHECK PROGRESS",
		]
	else:
		quest_status_label.text = "UP/DOWN SELECT    ENTER ACCEPT    ESC CLOSE"


func _on_board_changed() -> void:
	refresh()


func _on_quest_message(message: String) -> void:
	quest_status_label.text = message
	refresh()


func _is_key(key_event: InputEventKey, key_code: int) -> bool:
	return key_event.keycode == key_code or key_event.physical_keycode == key_code
