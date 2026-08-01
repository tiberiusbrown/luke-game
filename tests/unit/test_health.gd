extends GutTest

var health: HeartHealth


func before_each() -> void:
	health = HeartHealth.new(10)


func test_health_starts_full_and_uses_hearts_as_units() -> void:
	assert_eq(health.max_hearts, 10)
	assert_eq(health.current_hearts, 10)
	assert_false(health.is_depleted())


func test_damage_reduces_health_by_the_requested_number_of_hearts() -> void:
	assert_eq(health.take_damage(3), 3)
	assert_eq(health.current_hearts, 7)

	assert_eq(health.take_damage(8), 7)
	assert_eq(health.current_hearts, 0)
	assert_true(health.is_depleted())


func test_healing_cannot_exceed_maximum_hearts() -> void:
	health.take_damage(4)

	assert_eq(health.heal(8), 4)
	assert_eq(health.current_hearts, 10)
	assert_eq(health.heal(1), 0)
