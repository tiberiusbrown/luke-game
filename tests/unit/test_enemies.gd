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


func test_vampire_spider_and_ghost_have_their_requested_combat_stats() -> void:
	var vampire: VampireEnemy = VampireEnemy.new()
	var spider: SpiderEnemy = SpiderEnemy.new()
	var ghost: GhostEnemy = GhostEnemy.new()
	add_child_autofree(vampire)
	add_child_autofree(spider)
	add_child_autofree(ghost)

	assert_eq(vampire.health.max_hearts, 10)
	assert_eq(vampire.attack_damage, 2)
	assert_eq(vampire.hit_chance, 0.50)
	assert_eq(vampire.speed, player.speed)

	assert_eq(spider.health.max_hearts, 5)
	assert_eq(spider.attack_damage, 1)
	assert_eq(spider.hit_chance, 1.0)
	assert_eq(spider.speed, player.speed)

	assert_eq(ghost.health.max_hearts, 10)
	assert_eq(ghost.attack_damage, 1)
	assert_eq(ghost.hit_chance, 0.50)
	assert_eq(ghost.speed, player.speed)


func test_new_monsters_have_distinct_combat_stats() -> void:
	var goblin: GoblinEnemy = GoblinEnemy.new()
	var orc: OrcEnemy = OrcEnemy.new()
	var slime: SlimeEnemy = SlimeEnemy.new()
	var mummy: MummyEnemy = MummyEnemy.new()
	var wraith: WraithEnemy = WraithEnemy.new()
	var golem: GolemEnemy = GolemEnemy.new()
	var lich: LichEnemy = LichEnemy.new()
	add_child_autofree(goblin)
	add_child_autofree(orc)
	add_child_autofree(slime)
	add_child_autofree(mummy)
	add_child_autofree(wraith)
	add_child_autofree(golem)
	add_child_autofree(lich)

	assert_eq(goblin.get_display_name(), "Goblin")
	assert_eq(goblin.health.max_hearts, 6)
	assert_eq(goblin.attack_damage, 1)
	assert_eq(goblin.hit_chance, 0.80)
	assert_eq(goblin.speed, 1.5)

	assert_eq(orc.get_display_name(), "Orc")
	assert_eq(orc.health.max_hearts, 14)
	assert_eq(orc.attack_damage, 3)
	assert_eq(orc.hit_chance, 0.60)
	assert_eq(orc.speed, 0.65)

	assert_eq(slime.get_display_name(), "Slime")
	assert_eq(slime.health.max_hearts, 4)
	assert_eq(slime.attack_damage, 1)
	assert_eq(slime.hit_chance, 0.90)
	assert_eq(slime.speed, 1.25)

	assert_eq(mummy.get_display_name(), "Mummy")
	assert_eq(mummy.health.max_hearts, 12)
	assert_eq(mummy.attack_damage, 2)
	assert_eq(mummy.hit_chance, 0.65)
	assert_eq(mummy.speed, 0.75)

	assert_eq(wraith.get_display_name(), "Wraith")
	assert_eq(wraith.health.max_hearts, 7)
	assert_eq(wraith.attack_damage, 2)
	assert_eq(wraith.hit_chance, 0.65)
	assert_eq(wraith.speed, 1.5)

	assert_eq(golem.get_display_name(), "Golem")
	assert_eq(golem.health.max_hearts, 16)
	assert_eq(golem.attack_damage, 3)
	assert_eq(golem.hit_chance, 0.75)
	assert_eq(golem.speed, 0.5)

	assert_eq(lich.get_display_name(), "Lich")
	assert_eq(lich.health.max_hearts, 8)
	assert_eq(lich.attack_damage, 3)
	assert_eq(lich.hit_chance, 0.60)
	assert_eq(lich.speed, 1.0)


func test_cyclopes_is_a_boss_with_thirty_hearts_and_heavy_attacks() -> void:
	var cyclopes: CyclopesEnemy = CyclopesEnemy.new()
	add_child_autofree(cyclopes)

	assert_true(cyclopes.is_boss)
	assert_eq(cyclopes.get_display_name(), "Cyclopes")
	assert_eq(cyclopes.health.max_hearts, 30)
	assert_eq(cyclopes.attack_damage, 4)
	assert_eq(cyclopes.hit_chance, 0.90)
	assert_eq(cyclopes.get_attack_range(), 2)
	assert_eq(cyclopes.ATTACK_COOLDOWN, 0.8)
	assert_gt(cyclopes.speed, player.speed)


func test_monster_spawner_has_one_hundred_hearts_and_spawns_ten_monsters() -> void:
	var spawner: MonsterSpawner = dungeon_level.get_monster_spawner()
	var initial_enemy_count: int = dungeon_level.enemies.size()

	assert_not_null(spawner)
	assert_eq(spawner.health.max_hearts, 100)
	assert_eq(MonsterSpawner.SPAWN_INTERVAL, 5.0)
	assert_eq(MonsterSpawner.MONSTERS_PER_SPAWN, 10)
	assert_eq(spawner.spawn_monsters(), 10)
	assert_eq(dungeon_level.enemies.size(), initial_enemy_count + 10)


func test_cyclopes_deals_four_hearts_when_its_attack_hits() -> void:
	var cyclopes: CyclopesEnemy = CyclopesEnemy.new()
	cyclopes.hit_chance = 1.0
	dungeon_level.spawn_enemy(cyclopes, Vector2i(3, 2))

	assert_true(cyclopes.try_move(Vector2i(-1, 0)))
	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_eq(player.health.current_hearts, 6)


func test_cyclopes_can_attack_from_two_cells_away() -> void:
	var cyclopes: CyclopesEnemy = CyclopesEnemy.new()
	cyclopes.hit_chance = 1.0
	dungeon_level.spawn_enemy(cyclopes, Vector2i(4, 2))

	assert_true(cyclopes.take_turn())
	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_eq(player.health.current_hearts, 6)


func test_enemies_wait_for_a_player_move_before_taking_a_turn() -> void:
	var ghost: GhostEnemy = GhostEnemy.new()
	ghost.hit_chance = 1.0
	dungeon_level.spawn_enemy(ghost, Vector2i(3, 3))

	await get_tree().create_timer(0.25).timeout

	assert_eq(player.health.current_hearts, 10)
	assert_eq(ghost.current_cell, Vector2i(3, 3))

	assert_true(player.try_move(Vector2i(0, 1)))
	await get_tree().create_timer(0.75).timeout

	assert_eq(player.health.current_hearts, 9)


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


func test_lethal_player_attack_finishes_animation_after_target_is_freed() -> void:
	player.hit_chance = 1.0
	var enemy: ZombieEnemy = ZombieEnemy.new()
	dungeon_level.spawn_enemy(enemy, Vector2i(3, 2))
	var enemy_health: HeartHealth = enemy.health
	enemy_health.current_hearts = 1

	assert_true(player.try_move(Vector2i(1, 0)))
	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_true(enemy_health.is_depleted())
	assert_false(player.is_attacking)
	assert_null(dungeon_level.get_entity_at(Vector2i(3, 2)))


func test_enemy_attacks_by_moving_into_the_player() -> void:
	var enemy: ZombieEnemy = ZombieEnemy.new()
	enemy.hit_chance = 1.0
	dungeon_level.spawn_enemy(enemy, Vector2i(3, 2))

	assert_true(enemy.try_move(Vector2i(-1, 0)))
	assert_eq(enemy.get_current_cell(), Vector2i(3, 2))

	await get_tree().create_timer(HitEffect.DURATION + 0.1).timeout

	assert_eq(player.health.current_hearts, 8)
	assert_false(enemy.is_attacking)


func test_enemies_do_not_attack_each_other_when_one_blocks_the_chase_route() -> void:
	player.current_cell = Vector2i(2, 1)
	player.position = dungeon_level.cell_to_world(player.current_cell)

	var blocker: ZombieEnemy = ZombieEnemy.new()
	dungeon_level.spawn_enemy(blocker, Vector2i(3, 2))
	var follower: SkeletonEnemy = SkeletonEnemy.new()
	follower.hit_chance = 1.0
	dungeon_level.spawn_enemy(follower, Vector2i(4, 2))

	var blocker_hearts: int = blocker.health.current_hearts
	assert_true(follower.take_turn())
	assert_eq(follower.get_current_cell(), Vector2i(4, 1))
	assert_eq(blocker.health.current_hearts, blocker_hearts)
	assert_false(follower.is_attacking)

	await get_tree().create_timer(DungeonEntity.MOVE_DURATION + 0.05).timeout

	assert_false(follower.is_moving)


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


func test_player_can_move_while_enemy_animation_is_active_and_enemy_catches_up() -> void:
	var enemy: SkeletonEnemy = SkeletonEnemy.new()
	dungeon_level.spawn_enemy(enemy, Vector2i(4, 2))

	assert_true(enemy.take_turn())
	assert_true(enemy.is_moving)
	assert_true(player.try_move(Vector2i(0, 1)))
	assert_true(player.is_moving)

	await get_tree().create_timer(DungeonEntity.MOVE_DURATION * 0.75).timeout

	assert_false(enemy.is_moving)



func test_hit_effect_particle_amount_grows_with_damage() -> void:
	assert_gt(HitEffect.particle_amount_for_damage(2), HitEffect.particle_amount_for_damage(1))
	assert_eq(HitEffect.particle_amount_for_damage(1), HitEffect.PARTICLE_AMOUNT_MIN)
	assert_eq(HitEffect.particle_amount_for_damage(3), HitEffect.PARTICLE_AMOUNT_MAX)


func test_hit_effect_particles_render_above_entities_with_radial_gravity() -> void:
	var effect: HitEffect = HitEffect.new()
	effect.setup(1, Color.WHITE)
	add_child_autofree(effect)

	assert_eq(effect.z_index, HitEffect.EFFECT_Z_INDEX)
	assert_eq(effect._particles.emission_shape, CPUParticles2D.EMISSION_SHAPE_POINT)
	assert_eq(effect._particles.direction, Vector2.RIGHT)
	assert_eq(effect._particles.spread, 180.0)
	assert_eq(effect._particles.randomness, 1.0)
	assert_eq(effect._particles.gravity, Vector2(0.0, 96.0))


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
