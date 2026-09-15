extends SceneTree

const Suite = preload("res://test/foundation/support/test_suite.gd")
const GameRuntimeScript = preload("res://src/gameplay/game_runtime.gd")
const SelectionStateScript = preload("res://src/gameplay/ui/selection_state.gd")
const CommandCardModelScript = preload("res://src/gameplay/ui/command_card_model.gd")
const SettingsStoreScript = preload("res://src/gameplay/ui/settings_store.gd")
const LocalizationServiceScript = preload("res://src/core/localization/localization_service.gd")
const GemAssetLibraryScript = preload("res://src/gameplay/assets/gem_asset_library.gd")
const STONE_TEXTURE_PATH := "res://assets/art/gameplay/environment/stones/petrified_gem_rocks.png"

func _init() -> void:
    var suite := Suite.new()
    var runtime := GameRuntimeScript.new()
    var errors := runtime.initialize(707)
    suite.expect(errors.is_empty(), "M6 runtime initializes")
    suite.expect_equal(runtime.foundation.catalog.recipes.filter(func(recipe): return not recipe.secret).size(), 38, "exactly 38 normal recipes are visible")
    suite.expect_equal(runtime.foundation.catalog.recipes.filter(func(recipe): return recipe.secret).size(), 8, "secret recipes remain hidden from normal UI")
    var maximum_levels := {}
    for recipe in runtime.foundation.catalog.recipes:
        var maximum := 0
        for ingredient in recipe.ingredients: maximum = maxi(maximum, int(ingredient.get("level", 0)))
        maximum_levels[maximum] = true
    for level in range(1, 7): suite.expect(maximum_levels.has(level), "recipe catalog has maximum ingredient level %d" % level)
    var selection := SelectionStateScript.new()
    var commands := CommandCardModelScript.new()
    commands.rebuild(runtime, selection)
    suite.expect_equal(commands.actions.size(), 12, "command card has twelve slots")
    suite.expect_equal(commands.actions[0].hotkey, "Q", "command card starts at Q")
    suite.expect_equal(commands.actions[11].hotkey, "V", "command card ends at V")
    selection.select(SelectionStateScript.Kind.GEM, runtime.construction.board_gems[0] if not runtime.construction.board_gems.is_empty() else null)
    commands.rebuild(runtime, selection)
    suite.expect(commands.actions[2].enabled == false or runtime.construction.placed_count() < 5, "disabled command actions have no side effect")
    _check_incomplete_construction_popup_policy(suite)
    var settings := SettingsStoreScript.new()
    settings.fullscreen = false; settings.music_volume = 100; settings.sfx_volume = 100
    suite.expect(settings.music_volume == 100 and settings.sfx_volume == 100, "settings defaults are safe")
    var localization := LocalizationServiceScript.new()
    suite.expect(localization.validate_catalog().is_empty(), "EN/ES localization catalog is complete")
    localization.locale = "en"
    suite.expect_equal(localization.tr_key("game.settings.title"), "Settings", "M6 English keys are initialized before entering the tree")
    suite.expect_equal(localization.tr_key("welcome.enter.tooltip"), "Enter the kingdom", "M6 English welcome tooltip is localized")
    localization.locale = "es"
    suite.expect_equal(localization.tr_key("game.settings.title"), "Configuración", "M6 Spanish keys are initialized before entering the tree")
    suite.expect_equal(localization.tr_key("welcome.enter.tooltip"), "Ingresar al reino", "M6 Spanish welcome tooltip is localized")
    localization.locale = "en"
    suite.expect_equal(localization.tr_key("game.player.level", {"level": 2}), "Level 2", "MIC-81 English player level is localized")
    localization.locale = "es"
    suite.expect_equal(localization.tr_key("game.player.level", {"level": 2}), "Nivel 2", "MIC-81 Spanish player level is localized")
    suite.expect(not localization.tr_key("game.command.place_gem").begins_with("game."), "M6 never renders raw localization keys")
    var progression := runtime.progression
    progression.add_xp(2400)
    suite.expect_equal(progression.quality_level, 2, "MIC-81 levels up from the shared XP runtime")
    suite.expect(is_equal_approx(progression.progress_ratio(), 0.0), "MIC-81 XP bar rolls over at a level threshold")
    suite.expect_equal(progression.current_level_threshold(), 2400, "MIC-81 uses the current level threshold")
    suite.expect_equal(progression.next_level_threshold(), 6400, "MIC-81 uses the next level threshold")
    var enemy_visuals := [
        {"name": "necromancer cats", "sheet": "res://assets/art/gameplay/enemies/gatos_nigromantes/necromancer_cat.png", "icon": "res://assets/art/gameplay/enemies/gatos_nigromantes/necromancer_cat_icon.png"},
        {"name": "normal enemy", "sheet": "res://assets/art/gameplay/enemies/normal_enemies/necromancer_cat.png", "icon": "res://assets/art/gameplay/enemies/normal_enemies/necromancer_cat_icon.png"},
        {"name": "boss enemy", "sheet": "res://assets/art/gameplay/enemies/boss/necromancer_cat_boss.png", "icon": "res://assets/art/gameplay/enemies/boss/necromancer_cat_boss_icon.png"},
        {"name": "invisible enemy", "sheet": "res://assets/art/gameplay/enemies/invisibles/invisible_cat_w8.png", "icon": "res://assets/art/gameplay/enemies/invisibles/invisible_cat_w8_icon.png"}
    ]
    for visual: Dictionary in enemy_visuals:
        _check_enemy_visual(suite, visual)
    _check_base_gem_assets(suite)
    for gem_id in GemAssetLibrary.BASE_GEM_IDS:
        var definition := runtime.foundation.catalog.gem_definition_for_id(gem_id) as GemDefinition
        var level_two := GemInstance.new(gem_id, 2, GemInstance.Quality.FLAWED)
        suite.expect_equal(int(TowerCombatStats.level_data_for(level_two, definition).get("level", 0)), 2, "%s keeps level 2 stats tied to the same gem identity" % gem_id)
    if suite.failures.is_empty(): print("M6 UI and player experience tests passed")
    else:
        for failure in suite.failures: push_error(failure)
    quit(0 if suite.failures.is_empty() else 1)

func _check_incomplete_construction_popup_policy(suite) -> void:
    var policy_runtime := GameRuntimeScript.new()
    suite.expect(policy_runtime.initialize(708).is_empty(), "popup policy runtime initializes")
    var selected := GemInstance.new(&"amethyst", 1, GemInstance.Quality.CHIPPED)
    suite.expect(not CommandCardModelScript.can_open_gem_context_popup(policy_runtime, selected), "gem popup stays closed before construction reaches five gems")
    for index in range(ConstructionRuntime.MAX_PLACEMENTS):
        policy_runtime.construction.current_gems.append(GemInstance.new(&"amethyst", 1, GemInstance.Quality.CHIPPED))
    suite.expect(CommandCardModelScript.can_open_gem_context_popup(policy_runtime, selected), "gem popup becomes available at five placed gems")

func _check_enemy_visual(suite, visual: Dictionary) -> void:
    var sheet := load(visual.sheet) as Texture2D
    var icon := load(visual.icon) as Texture2D
    suite.expect(sheet != null, "%s sheet loads" % visual.name)
    suite.expect(icon != null, "%s icon loads" % visual.name)
    if sheet != null:
        suite.expect(sheet.get_width() % 3 == 0 and sheet.get_height() % 4 == 0, "%s sheet is a 3x4 atlas" % visual.name)
        var sheet_image := Image.load_from_file(visual.sheet)
        suite.expect(sheet_image != null and sheet_image.get_pixel(0, 0).a < 1.0, "%s sheet preserves transparency" % visual.name)
    if icon != null:
        suite.expect(icon.get_width() == icon.get_height(), "%s icon is square" % visual.name)
        var icon_image := Image.load_from_file(visual.icon)
        suite.expect(icon_image != null and icon_image.get_pixel(0, 0).a < 1.0, "%s icon preserves transparency" % visual.name)
    if sheet != null and icon != null:
        suite.expect(sheet.get_width() == icon.get_width() * 3 and sheet.get_height() == icon.get_height() * 4, "%s atlas frames match icon dimensions" % visual.name)

func _check_base_gem_assets(suite) -> void:
    var library: GemAssetLibrary = GemAssetLibraryScript.new()
    var gem_dimensions := library.atlas_dimensions(GemAssetLibrary.AssetKind.GEM)
    var tower_dimensions := library.atlas_dimensions(GemAssetLibrary.AssetKind.TOWER)
    suite.expect(gem_dimensions.x > 0 and gem_dimensions.y > 0, "base gem atlas loads")
    suite.expect(tower_dimensions.x > 0 and tower_dimensions.y > 0, "base tower atlas loads")
    suite.expect(gem_dimensions.x % GemAssetLibrary.GRID_COLUMNS == 0 and gem_dimensions.y % GemAssetLibrary.GRID_ROWS == 0, "base gem atlas has uniform 8x7 cells")
    suite.expect(tower_dimensions.x % GemAssetLibrary.GRID_COLUMNS == 0 and tower_dimensions.y % GemAssetLibrary.GRID_ROWS == 0, "base tower atlas has uniform 8x7 cells")
    var gem_image := Image.load_from_file(GemAssetLibrary.GEM_ATLAS_PATH)
    var tower_image := Image.load_from_file(GemAssetLibrary.TOWER_ATLAS_PATH)
    suite.expect(gem_image != null and gem_image.get_pixel(0, 0).a < 1.0, "base gem atlas preserves transparency")
    suite.expect(tower_image != null and tower_image.get_pixel(0, 0).a < 1.0, "base tower atlas preserves transparency")
    for gem_id in GemAssetLibrary.BASE_GEM_IDS:
        for level in range(1, GemAssetLibrary.GRID_ROWS + 1):
            suite.expect(library.get_gem_texture(gem_id, level) != null, "%s gem level %d has a texture" % [gem_id, level])
            suite.expect(library.get_tower_texture(gem_id, level) != null, "%s tower level %d has a texture" % [gem_id, level])
            var anchor := library.get_tower_visual_anchor(gem_id, level)
            var visible_fraction := library.get_tower_visible_fraction(gem_id, level)
            suite.expect(anchor.x > 0.0 and anchor.x < 1.0, "%s tower level %d has a horizontal visual anchor" % [gem_id, level])
            suite.expect(anchor.y > 0.5 and anchor.y <= 1.0, "%s tower level %d has a visible base anchor" % [gem_id, level])
            suite.expect(visible_fraction.x > 0.0 and visible_fraction.y > 0.0, "%s tower level %d has measurable opaque bounds" % [gem_id, level])
            var normalized_outer_size := GemAssetLibrary.TOWER_VISIBLE_CELLS / maxf(visible_fraction.x, visible_fraction.y)
            suite.expect(is_equal_approx(normalized_outer_size * maxf(visible_fraction.x, visible_fraction.y), GemAssetLibrary.TOWER_VISIBLE_CELLS), "%s tower level %d normalizes to the tower visible size" % [gem_id, level])
            suite.expect_equal(library.get_tower_visual_anchor(gem_id, level), anchor, "%s tower level %d reuses its cached anchor" % [gem_id, level])
    suite.expect(is_equal_approx(GemAssetLibrary.TOWER_VISIBLE_CELLS, 1.4175), "towers use the five-percent larger visible footprint")
    suite.expect(is_equal_approx(GemAssetLibrary.STONE_VISIBLE_CELLS, 0.9), "stones use a compact 0.9-cell visible footprint")
    suite.expect(is_equal_approx(GemAssetLibrary.GEM_SPRITE_CELLS, 3.05), "unfinished gems use the reduced visual scale")
    suite.expect(is_equal_approx(GemAssetLibrary.TOWER_BASE_CELL_Y, 0.75), "tower pedestals rest at 75 percent of their logical cell")
    suite.expect(library.get_gem_texture(&"silver", 1) == null, "combined gems keep legacy visual fallback")
    suite.expect(library.validate_base_assets().is_empty(), "MIC-83 validates every base gem and tower asset mapping")
    suite.expect(library.get_gem_texture(&"amethyst", 0) == null and library.get_tower_texture(&"amethyst", 8) == null, "invalid base asset indexes are rejected")
    var stone_texture := load(STONE_TEXTURE_PATH) as Texture2D
    suite.expect(stone_texture != null, "the single petrified stone texture loads")
    if stone_texture != null:
        suite.expect_equal(Vector2i(stone_texture.get_width(), stone_texture.get_height()), Vector2i(1286, 1223), "the selected single stone asset replaces the former composition")
