extends RefCounted

const ProgressRuntimeScript = preload("res://src/gameplay/progression/progress_runtime.gd")
const EconomyRuntimeScript = preload("res://src/gameplay/progression/economy_runtime.gd")
const PlayerProgressionRuntimeScript = preload("res://src/gameplay/progression/player_progression_runtime.gd")
const GameOutcomeRuntimeScript = preload("res://src/gameplay/progression/game_outcome_runtime.gd")
const SupportSkillCatalogScript = preload("res://src/gameplay/progression/support_skill_catalog.gd")

func run(suite: FoundationTestSuite) -> void:
	var progress = ProgressRuntimeScript.new(); progress.reset(); suite.expect(is_equal_approx(progress.value, 50.0), "progress starts at 50")
	progress.on_kill(); suite.expect(is_equal_approx(progress.value, 50.75), "regular kill adds 0.75 progress")
	progress.reset(); progress.on_checkpoint(0, false); suite.expect(is_equal_approx(progress.value, 50.0), "checkpoint one has no penalty"); progress.on_checkpoint(1, false); suite.expect(is_equal_approx(progress.value, 49.75), "checkpoint two regular penalty is 0.25"); progress.reset(); progress.on_final_checkpoint(true); suite.expect(is_equal_approx(progress.value, 40.0), "boss final escape penalty is 10")
	progress.value = 99.8; progress.add(0.5); suite.expect(progress.value < 100.0 and progress.future_count_modifier == 1, "progress rolls over before exposing 100")
	var economy = EconomyRuntimeScript.new(); economy.reset(); suite.expect_equal(economy.gold, 0, "gold starts at zero"); suite.expect(economy.reward(1, 5, &"death"), "kill grants gold"); suite.expect(not economy.reward(1, 5, &"death"), "duplicate death does not duplicate gold"); economy.reward(2, 0, &"escaped"); suite.expect_equal(economy.gold, 5, "escape grants no gold")
	var progression = PlayerProgressionRuntimeScript.new(); progression.reset(); progression.add_xp(2400); suite.expect(progression.xp == 2400 and progression.quality_level == 2, "canonical XP threshold advances quality"); progression.add_xp(20000); suite.expect_equal(progression.xp, 17600, "XP caps at level five threshold")
	var outcome = GameOutcomeRuntimeScript.new(); outcome.reset(); outcome.register_escape(100); suite.expect_equal(outcome.life, 900, "escape reduces life by attack")
	outcome.register_escape(900); suite.expect_equal(outcome.life, 0, "zero life is clamped"); suite.expect(outcome.finished, "zero life triggers defeat once")
	var skills = SupportSkillCatalogScript.new(); suite.expect(skills.acquire(&"fixed_hammer", 4) != null, "support skill level four is valid"); suite.expect(skills.acquire(&"fixed_hammer", 5) == null, "support skill level five is rejected")
