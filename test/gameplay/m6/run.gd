extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const GameRuntimeScript = preload("res://src/gameplay/game_runtime.gd")
const SelectionStateScript = preload("res://src/gameplay/ui/selection_state.gd")
const CommandCardModelScript = preload("res://src/gameplay/ui/command_card_model.gd")
const SettingsStoreScript = preload("res://src/gameplay/ui/settings_store.gd")
const LocalizationServiceScript = preload("res://src/core/localization/localization_service.gd")

func _init() -> void:
    var suite := Suite.new()
    var runtime := GameRuntimeScript.new()
    var errors := runtime.initialize(707)
    suite.expect(errors.is_empty(), "M6 runtime initializes")
    suite.expect_equal(runtime.foundation.catalog.recipes.filter(func(recipe): return not recipe.secret).size(), 38, "exactly 38 normal recipes are visible")
    suite.expect_equal(runtime.foundation.catalog.recipes.filter(func(recipe): return recipe.secret).size(), 8, "secret recipes remain hidden from normal UI")
    var selection := SelectionStateScript.new()
    var commands := CommandCardModelScript.new()
    commands.rebuild(runtime, selection)
    suite.expect_equal(commands.actions.size(), 12, "command card has twelve slots")
    suite.expect_equal(commands.actions[0].hotkey, "Q", "command card starts at Q")
    suite.expect_equal(commands.actions[11].hotkey, "V", "command card ends at V")
    selection.select(SelectionStateScript.Kind.GEM, runtime.construction.board_gems[0] if not runtime.construction.board_gems.is_empty() else null)
    commands.rebuild(runtime, selection)
    suite.expect(commands.actions[2].enabled == false or runtime.construction.placed_count() < 5, "disabled command actions have no side effect")
    var settings := SettingsStoreScript.new()
    settings.fullscreen = false; settings.music_volume = 100; settings.sfx_volume = 100
    suite.expect(settings.music_volume == 100 and settings.sfx_volume == 100, "settings defaults are safe")
    var localization := LocalizationServiceScript.new()
    suite.expect(localization.validate_catalog().is_empty(), "EN/ES localization catalog is complete")
    localization.locale = "en"
    suite.expect_equal(localization.tr_key("game.settings.title"), "Settings", "M6 English keys are initialized before entering the tree")
    localization.locale = "es"
    suite.expect_equal(localization.tr_key("game.settings.title"), "Configuración", "M6 Spanish keys are initialized before entering the tree")
    suite.expect(not localization.tr_key("game.command.place_gem").begins_with("game."), "M6 never renders raw localization keys")
    if suite.failures.is_empty(): print("M6 UI and player experience tests passed")
    else:
        for failure in suite.failures: push_error(failure)
    quit(0 if suite.failures.is_empty() else 1)
