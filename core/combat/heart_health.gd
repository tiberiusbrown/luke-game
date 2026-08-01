class_name HeartHealth
extends RefCounted

signal health_changed(current_hearts: int, max_hearts: int)
signal depleted

const MIN_HEARTS: int = 1

var max_hearts: int
var current_hearts: int


func _init(new_max_hearts: int = MIN_HEARTS) -> void:
	max_hearts = maxi(new_max_hearts, MIN_HEARTS)
	current_hearts = max_hearts


func take_damage(damage_hearts: int) -> int:
	if current_hearts <= 0:
		return 0

	var safe_damage: int = maxi(damage_hearts, 0)
	if safe_damage == 0:
		return 0

	var previous_hearts: int = current_hearts
	current_hearts = maxi(current_hearts - safe_damage, 0)
	var damage_dealt: int = previous_hearts - current_hearts
	health_changed.emit(current_hearts, max_hearts)
	if current_hearts == 0:
		depleted.emit()
	return damage_dealt


func heal(healing_hearts: int) -> int:
	var safe_healing: int = maxi(healing_hearts, 0)
	if safe_healing == 0 or current_hearts >= max_hearts:
		return 0

	var previous_hearts: int = current_hearts
	current_hearts = mini(current_hearts + safe_healing, max_hearts)
	var healing_done: int = current_hearts - previous_hearts
	health_changed.emit(current_hearts, max_hearts)
	return healing_done


func reset() -> void:
	if current_hearts == max_hearts:
		return
	current_hearts = max_hearts
	health_changed.emit(current_hearts, max_hearts)


func is_depleted() -> bool:
	return current_hearts <= 0
