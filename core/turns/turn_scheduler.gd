class_name TurnScheduler
extends RefCounted

signal time_advanced(current_time: float)

const BASE_TURN_DURATION: float = 1.0
const MIN_SPEED: float = 0.01
const TIME_EPSILON: float = 0.0001

var current_time: float = 0.0

var _entities: Array[DungeonEntity] = []
var _next_action_times: Dictionary = {}
var _registration_order: Dictionary = {}
var _next_registration_order: int = 0


func add_entity(entity: DungeonEntity) -> void:
	if entity == null or _entities.has(entity):
		return

	_entities.append(entity)
	_next_action_times[entity] = current_time + get_action_interval(entity.speed)
	_registration_order[entity] = _next_registration_order
	_next_registration_order += 1


func remove_entity(entity: DungeonEntity) -> void:
	if entity == null:
		return

	_entities.erase(entity)
	_next_action_times.erase(entity)
	_registration_order.erase(entity)


func has_entity(entity: DungeonEntity) -> bool:
	return entity != null and _entities.has(entity)


func get_entities() -> Array[DungeonEntity]:
	return _entities.duplicate()


func get_action_interval(entity_speed: float) -> float:
	return BASE_TURN_DURATION / maxf(entity_speed, MIN_SPEED)


func get_next_action_time(entity: DungeonEntity) -> float:
	if entity == null or not _next_action_times.has(entity):
		return INF
	return float(_next_action_times[entity])


func advance_after_action(entity: DungeonEntity) -> Array[DungeonEntity]:
	if entity == null:
		return []
	if not has_entity(entity):
		add_entity(entity)

	var scheduled_time: float = get_next_action_time(entity)
	current_time = maxf(current_time, scheduled_time)
	_next_action_times[entity] = current_time + get_action_interval(entity.speed)
	time_advanced.emit(current_time)
	return _collect_due_entities()


func _collect_due_entities() -> Array[DungeonEntity]:
	var due_events: Array[Dictionary] = []
	for entity: DungeonEntity in _entities:
		if not is_instance_valid(entity) or entity.health.is_depleted():
			continue

		var next_time: float = float(_next_action_times.get(entity, INF))
		var interval: float = get_action_interval(entity.speed)
		while next_time <= current_time + TIME_EPSILON:
			due_events.append({
				"entity": entity,
				"time": next_time,
				"order": int(_registration_order.get(entity, 0)),
			})
			next_time += interval
		_next_action_times[entity] = next_time

	due_events.sort_custom(_sort_due_events)
	var due_entities: Array[DungeonEntity] = []
	for event: Dictionary in due_events:
		due_entities.append(event["entity"] as DungeonEntity)
	return due_entities


func _sort_due_events(first: Dictionary, second: Dictionary) -> bool:
	var first_time: float = float(first["time"])
	var second_time: float = float(second["time"])
	if not is_equal_approx(first_time, second_time):
		return first_time < second_time
	return int(first["order"]) < int(second["order"])
