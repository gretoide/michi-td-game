extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const M7PlaythroughScript = preload("res://test/gameplay/m7/playthrough.gd")

func _init() -> void:
    var suite := Suite.new()
    var first := M7PlaythroughScript.new()
    first.seed_value = 424242
    var first_result: Dictionary = first.execute()
    suite.expect(bool(first_result.get("ok", false)), "deterministic playthrough reaches a terminal victory: %s | %s" % [first_result.get("error", ""), "; ".join(first_result.get("log", PackedStringArray()))])
    suite.expect(str(first_result.get("signature", "")).begins_with("victory|"), "terminal signature records victory")
    var second := M7PlaythroughScript.new()
    second.seed_value = 424242
    var second_result: Dictionary = second.execute()
    suite.expect_equal(second_result.get("signature", ""), first_result.get("signature", ""), "same seed produces same terminal signature")
    suite.expect_equal(first.log_lines.size(), second.log_lines.size(), "same seed produces same wave log length")
    if suite.failures.is_empty(): print("M7 deterministic playthrough tests passed")
    else:
        for failure in suite.failures: push_error(failure)
    quit(0 if suite.failures.is_empty() else 1)
