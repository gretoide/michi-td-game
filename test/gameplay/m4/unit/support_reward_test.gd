extends RefCounted

const SupportSkillCatalogScript = preload("res://src/gameplay/progression/support_skill_catalog.gd")
const SupportRewardRuntimeScript = preload("res://src/gameplay/progression/support_reward_runtime.gd")
const SeededRandomSourceScript = preload("res://src/core/random/seeded_random_source.gd")

func run(suite: FoundationTestSuite) -> void:
	var catalog := SupportSkillCatalogScript.new(); catalog.reset()
	var rewards := SupportRewardRuntimeScript.new(); rewards.setup(catalog, SeededRandomSourceScript.new(9)); rewards.reset()
	suite.expect_equal(rewards.generate_for_wave(4).size(), 0, "no reward before a multiple of five")
	var first: Array[StringName] = rewards.generate_for_wave(5); suite.expect_equal(first.size(), 3, "wave five offers three candidates"); suite.expect_equal(first.duplicate().size(), 3, "reward candidates are unique")
	var chosen: RefCounted = rewards.choose(first[0]); suite.expect(chosen != null and catalog.skills.size() == 1, "choosing a candidate acquires level one")
	suite.expect_equal(rewards.generate_for_wave(10).size(), 3, "wave ten offers another reward")
	var owned := catalog.skills.keys()[0] as StringName; rewards.choose(owned); suite.expect_equal(catalog.skills[owned].level, 2, "choosing an owned candidate upgrades it")
	for skill_id in SupportSkillCatalogScript.IDS: catalog.acquire(skill_id, 1)
	suite.expect_equal(rewards.generate_for_wave(15).size(), 3, "four owned skills offer upgrade candidates")
	suite.expect_equal(rewards.generate_for_wave(50).size(), 0, "final wave has no reward")
