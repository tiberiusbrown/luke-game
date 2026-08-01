extends Node2D

@onready var dungeon_level: DungeonLevel = $DungeonLevel
@onready var player: DungeonPlayer = $DungeonLevel/Player
@onready var position_label: Label = $Hud/PositionLabel


func _ready() -> void:
	position_label.text = _get_position_text()


func _process(_delta: float) -> void:
	position_label.text = _get_position_text()


func _get_position_text() -> String:
	var cell: Vector2i = player.get_current_cell()
	return "POSITION  %02d, %02d" % [cell.x, cell.y]
