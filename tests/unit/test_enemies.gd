extends GutTest

var dungeon_level: DungeonLevel
var player: DungeonPlayer


func before_each() -> void:
	dungeon_level = DungeonLevel.new()
	add_child_autofree(dungeon_level)
	dungeon_level._clear_enemies()
	dungeon_level.clear_pickups()
	_set_up_test_map()

	player = DungeonPlayer.new()
	dungeon_level.add_child(player)
	_place_entity(player, Vector2i(2, 2))


func test_zombie_and_skeleton_have_their_requested_combat_stats() -> void:
	var zombie: ZombieEnemy = ZombieEnemy.new()
	var skeleton: SkeletonEnemy = SkeletonEnemy.new()
	add_child_autofree(zombie)
	add_child_autofree(skeleton)

	assert_eq(zombie.health.max_hearts, 10)
	assert_eq(zombie.attack_damage, 2)
	assert_eq(zombie.hit_chance, 0.50)
	assert_eq(skeleton.health.max_hearts, 10)
	assert_eq(skeleton.attack_damage, 1)
	assert_eq(skeleton.hit_chance, 0.75)
	assert_lt(zombie.speed, player.speed)
	assert_gt(skeleton.speed, player.speed)


func test_player_damage_is_base_damage_plus_wielded_weapon_damage() -> void:
	assert_eq(player.get_attack_damage(), DungeonPlayer.BASE_ATTACK_DAMAGE)
	var weapon: WeaponData = WeaponData.new("Bone Axe", 3)
	player.inventory.add_weapon(weapon)
	assert_true(player.inventory.wield_weapon(weapon))

	assert_eq(player.get_attack_damage(), DungeonPlayer.BASE_ATTACK_DAMAGE + weapon.attack_damage)
	assert_eq(player.get_hit_chance(), DungeonPlayer.HIT_CHANCE)


func test_player_attacks_by_moving_into_an_enemy_and_uses_animation() -> void:
	player.hit_chance = 1.0
	var enemy: ZombieEnemy = ZombieEnemy.new()
	dungeon_level.spawn_enemy(enemy, Vector2i(3, 2))

	assert_true(player.try_move(Vector2i(1, 0)))
	assert_eq(player.get_current_cell(), Vector2i(2, 2))
	assert_true(player.is_attacking)

	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_false(player.is_attacking)
	assert_eq(enemy.health.current_hearts, 9)
	assert_eq(enemy.get_current_cell(), Vector2i(3, 2))


func test_enemy_attacks_by_moving_into_the_player() -> void:
	var enemy: ZombieEnemy = ZombieEnemy.new()
	enemy.hit_chance = 1.0
	dungeon_level.spawn_enemy(enemy, Vector2i(3, 2))

	assert_true(enemy.try_move(Vector2i(-1, 0)))
	assert_eq(enemy.get_current_cell(), Vector2i(3, 2))

	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_eq(player.health.current_hearts, 8)
	assert_false(enemy.is_attacking)


func test_enemy_movement_is_animated_to_the_target_cell() -> void:
	var enemy: SkeletonEnemy = SkeletonEnemy.new()
	dungeon_level.spawn_enemy(enemy, Vector2i(4, 2))

	assert_true(enemy.take_turn())
	assert_true(enemy.is_moving)
	assert_eq(enemy.position, dungeon_level.cell_to_world(Vector2i(4, 2)))

	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout

	assert_false(enemy.is_moving)
	assert_eq(enemy.get_current_cell(), Vector2i(3, 2))
	assert_eq(enemy.position, dungeon_level.cell_to_world(Vector2i(3, 2)))


func test_hit_effect_particle_amount_grows_with_damage() -> void:
	assert_gt(HitEffect.particle_amount_for_damage(2), HitEffect.particle_amount_for_damage(1))
	assert_eq(HitEffect.particle_amount_for_damage(1), 8)
	assert_eq(HitEffect.particle_amount_for_damage(3), 16)


func _set_up_test_map() -> void:
	dungeon_level.tiles.clear()
	for y: int in range(DungeonLevel.GRID_HEIGHT):
		var row: Array[int] = []
		for _x: int in range(DungeonLevel.GRID_WIDTH):
			row.append(DungeonLevel.FLOOR)
		dungeon_level.tiles.append(row)


func _place_entity(entity: DungeonEntity, cell: Vector2i) -> void:
	entity.current_cell = cell
	entity.position = dungeon_level.cell_to_world(cell)
