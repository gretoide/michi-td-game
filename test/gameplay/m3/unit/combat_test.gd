extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var gem := GemInstance.new(&"ruby", 1, GemInstance.Quality.CHIPPED)
	var definition := GemDefinition.new(); definition.id = &"ruby"; definition.levels = [{"level": 1, "damage": 100.0, "range": 500.0, "base_attack_speed": 100.0, "bat": 1.0}]
	var stats := TowerCombatStats.from_gem(gem, definition)
	suite.expect_equal(stats.attack_interval(), 1.0, "attack interval follows BAT and AS")
	stats.attack_speed_bonus = 1000.0; suite.expect_equal(stats.total_attack_speed(), 700.0, "attack speed upper clamp")
	stats.attack_speed_bonus = -1000.0; suite.expect_equal(stats.total_attack_speed(), 20.0, "attack speed lower clamp")

	var profile := EnemyProfileDefinition.new(); profile.id = &"test"; profile.hp = 100.0; profile.armor = 0.0; profile.magic_resistance = 50.0
	var enemy_a := EnemyRuntime.new(); enemy_a.setup(1, profile, Vector2(100, 0)); var enemy_b := EnemyRuntime.new(); enemy_b.setup(2, profile, Vector2(200, 0))
	var targeting := TargetController.new(); suite.expect(targeting.acquire(Vector2.ZERO, 500.0, [enemy_a, enemy_b]) == enemy_a, "FIFO selects first enemy")
	suite.expect(targeting.set_manual(enemy_b, Vector2.ZERO, 500.0), "manual targeting accepts in-range enemy")
	suite.expect(not targeting.set_manual(enemy_b, Vector2.ZERO, 50.0), "manual targeting rejects out-of-range enemy")
	targeting.toggle_stop(); suite.expect(targeting.acquire(Vector2.ZERO, 500.0, [enemy_a, enemy_b]) == null, "stop prevents targeting")

	var physical := DamagePipeline.DamageContext.new(); physical.base_damage = 100.0; physical.damage_type = DamagePipeline.DamageType.PHYSICAL
	enemy_a.apply_damage(DamagePipeline.resolve(physical, enemy_a)); suite.expect_equal(enemy_a.hp, 0.0, "physical damage reaches target")
	var magic_target := EnemyRuntime.new(); magic_target.setup(3, profile, Vector2.ZERO)
	var magic := DamagePipeline.DamageContext.new(); magic.base_damage = 100.0; magic.damage_type = DamagePipeline.DamageType.MAGIC
	suite.expect_equal(DamagePipeline.resolve(magic, magic_target).final_damage, 50.0, "magic resistance halves magic damage")
	magic_target.is_magic_immune = true; suite.expect_equal(DamagePipeline.resolve(magic, magic_target).final_damage, 0.0, "magic immunity blocks magic damage")
	var pure := DamagePipeline.DamageContext.new(); pure.base_damage = 100.0; pure.damage_type = DamagePipeline.DamageType.PURE
	suite.expect_equal(DamagePipeline.resolve(pure, magic_target).final_damage, 100.0, "pure damage ignores defenses")

	var projectile_target := EnemyRuntime.new(); projectile_target.setup(4, profile, Vector2(100, 0))
	var projectile := HomingProjectile.new(); projectile.setup(Vector2.ZERO, projectile_target, physical, 1000.0)
	suite.expect(projectile.tick(0.05), "projectile travels before impact")
	suite.expect(not projectile.tick(0.05), "projectile resolves on impact")

	var slow_target := EnemyRuntime.new(); slow_target.setup(5, profile, Vector2.ZERO)
	var effect_system := EffectSystem.new(); suite.expect(effect_system.apply_slow(slow_target, &"tower", 999.0, 1.0), "slow applies to non-immune target")
	magic_target.is_magic_immune = true; suite.expect(not effect_system.apply_slow(magic_target, &"other", 10.0, 1.0), "magic immunity rejects magical effects")
	suite.expect(effect_system.apply_stone_gaze(magic_target, &"tower", 1.0), "non-magical effect bypasses magic immunity")
	suite.expect_equal(effect_system.effective_move_speed(100.0, [200.0]), 20.0, "slow respects minimum movement speed")
	var dot_target := EnemyRuntime.new(); dot_target.setup(6, profile, Vector2.ZERO); dot_target.magic_resistance = 0.0
	effect_system.apply_burn(dot_target, &"tower", 5.0, 1.0); effect_system.tick(0.24); suite.expect_equal(dot_target.hp, 100.0, "burn waits for its 0.25 second tick")
	effect_system.tick(0.01); suite.expect_equal(dot_target.hp, 95.0, "burn applies one tick every 0.25 seconds")
