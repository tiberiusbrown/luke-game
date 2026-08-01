extends GutTest

var scheduler: TurnScheduler
var slow_entity: DungeonEntity
var fast_entity: DungeonEntity


func before_each() -> void:
	scheduler = TurnScheduler.new()
	slow_entity = DungeonEntity.new()
	fast_entity = DungeonEntity.new()
	add_child_autofree(slow_entity)
	add_child_autofree(fast_entity)
	slow_entity.speed = 1.0
	fast_entity.speed = 2.0
	scheduler.add_entity(slow_entity)
	scheduler.add_entity(fast_entity)


func test_action_interval_is_inverse_of_entity_speed() -> void:
	assert_eq(scheduler.get_action_interval(1.0), 1.0)
	assert_eq(scheduler.get_action_interval(2.0), 0.5)
	assert_eq(scheduler.get_action_interval(0.0), 100.0)


func test_advancing_one_slow_action_can_schedule_two_fast_actions() -> void:
	var due_entities: Array[DungeonEntity] = scheduler.advance_after_action(slow_entity)

	assert_eq(scheduler.current_time, 1.0)
	assert_eq(due_entities.size(), 2)
	assert_eq(due_entities[0], fast_entity)
	assert_eq(due_entities[1], fast_entity)
	assert_eq(scheduler.get_next_action_time(fast_entity), 1.5)


func test_removing_an_entity_prevents_future_actions() -> void:
	scheduler.remove_entity(fast_entity)
	var due_entities: Array[DungeonEntity] = scheduler.advance_after_action(slow_entity)

	assert_true(due_entities.is_empty())
	assert_false(scheduler.has_entity(fast_entity))
