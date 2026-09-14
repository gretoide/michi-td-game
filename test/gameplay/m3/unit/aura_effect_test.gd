extends RefCounted

func run(suite: FoundationTestSuite) -> void:
	var profile := EnemyProfileDefinition.new(); profile.id = &"test"; profile.hp = 100.0
	var inside := EnemyRuntime.new(); inside.setup(1, profile, Vector2(100, 0)); var outside := EnemyRuntime.new(); outside.setup(2, profile, Vector2(500, 0))
	var effect := EffectRuntime.new(); effect.setup(&"slow", &"aura", 1.0, true); effect.effect_school = &"Magical"
	var aura := AuraRuntime.new(); aura.setup(&"slow_aura", &"tower", Vector2.ZERO, 200.0, effect)
	var applications := [0]
	aura.evaluate([inside, outside], func(target: EnemyRuntime, _value: EffectRuntime): applications[0] += 1)
	aura.evaluate([inside, outside], func(target: EnemyRuntime, _value: EffectRuntime): applications[0] += 1)
	suite.expect_equal(applications[0], 1, "aura does not duplicate effects while target remains inside")
	suite.expect(aura.affected.has(inside.id) and not aura.affected.has(outside.id), "aura tracks targets by radius")
