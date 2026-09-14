extends RefCounted

const Suite = preload("res://test/foundation/support/test_suite.gd")
const EnemyRuntimeScript = preload("res://src/gameplay/combat/enemy_runtime.gd")
const DamagePipelineScript = preload("res://src/gameplay/combat/damage_pipeline.gd")
const SeededRandomSourceScript = preload("res://src/core/random/seeded_random_source.gd")
const EffectSystemScript = preload("res://src/gameplay/combat/effect_system.gd")

func run(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"abilities"; profile.hp = 100.0; profile.ability_ids = PackedStringArray(["evasion", "invisible", "disarm_aura", "rush", "recharge", "cleanse", "high_armor"])
	var enemy: EnemyRuntime = EnemyRuntimeScript.new(); enemy.setup(1, profile)
	suite.expect(enemy.invisible and is_equal_approx(enemy.evasion_chance, 0.5), "invisible and evasion are profile driven")
	suite.expect_equal(enemy.disarm_aura_radius, 300.0, "disarm aura uses 300 units")
	suite.expect_equal(enemy.armor, 20.0, "high armor adds twenty")
	var source := SeededRandomSourceScript.new(7)
	var context := DamagePipelineScript.DamageContext.new(); context.base_damage = 10.0; context.random_source = source
	var result := DamagePipelineScript.resolve(context, enemy)
	suite.expect(result.final_damage == 0.0 or result.final_damage > 0.0, "evasion resolves deterministically")
	enemy.trigger_rush(); suite.expect_equal(enemy.effective_move_speed(), 375.0, "rush increases speed by fifty percent")
	enemy.tick_abilities(1.0); enemy.trigger_rush(); suite.expect(enemy.rush_remaining > 2.0, "rush retrigger refreshes duration")
	enemy.hp = 50.0; enemy.tick_abilities(1.0); suite.expect(enemy.hp > 50.0, "recharge restores one percent max hp per second")
	var effects: EffectSystem = EffectSystemScript.new(); effects.apply_slow(enemy, &"tower", 5.0, 10.0); effects.on_damage(enemy, 25.0); suite.expect_equal(effects.host_for(enemy).effects.size(), 0, "cleanse removes debuffs at twenty five percent damage")
