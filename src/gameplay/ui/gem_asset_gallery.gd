class_name GemAssetGallery
extends Control

const GemAssetLibraryScript = preload("res://src/gameplay/assets/gem_asset_library.gd")

var library: GemAssetLibrary
var close_requested: Callable
var visual_assets: VisualAssetConfig

func setup(asset_library: GemAssetLibrary, on_close: Callable, shared_visual_assets: VisualAssetConfig = null) -> void:
    library = asset_library
    close_requested = on_close
    visual_assets = shared_visual_assets if shared_visual_assets != null else VisualAssetConfig.new()
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_STOP
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _build()

func _build() -> void:
    var backdrop := ColorRect.new()
    backdrop.color = Color(0.025, 0.045, 0.075, 0.98)
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(backdrop)
    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 18)
    margin.add_theme_constant_override("margin_top", 14)
    margin.add_theme_constant_override("margin_right", 18)
    margin.add_theme_constant_override("margin_bottom", 14)
    add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    margin.add_child(column)
    var header := HBoxContainer.new()
    var title := Label.new()
    title.text = "Base gem and tower atlas gallery"
    title.add_theme_font_size_override("font_size", 20)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)
    var close := Button.new()
    close.text = ""
    close.icon = visual_assets.close
    close.expand_icon = true
    close.add_theme_constant_override("icon_max_width", 26)
    close.tooltip_text = LocalizationService.tr_key("game.close")
    close.custom_minimum_size = Vector2(42, 34)
    CursorManager.set_clickable(close)
    close.pressed.connect(func(): close_requested.call() if close_requested.is_valid() else queue_free())
    header.add_child(close)
    column.add_child(header)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    var content := VBoxContainer.new()
    content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 12)
    scroll.add_child(content)
    _add_section(content, "GEMS · 8 x 7", GemAssetLibrary.AssetKind.GEM)
    _add_section(content, "TOWERS · 8 x 7", GemAssetLibrary.AssetKind.TOWER)

func _add_section(parent: VBoxContainer, title_text: String, kind: GemAssetLibrary.AssetKind) -> void:
    var title := Label.new()
    title.text = title_text
    title.add_theme_font_size_override("font_size", 17)
    parent.add_child(title)
    var grid := GridContainer.new()
    grid.columns = GemAssetLibrary.GRID_COLUMNS
    grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    grid.add_theme_constant_override("h_separation", 6)
    grid.add_theme_constant_override("v_separation", 6)
    parent.add_child(grid)
    for level in range(1, GemAssetLibrary.GRID_ROWS + 1):
        for gem_id in GemAssetLibrary.BASE_GEM_IDS:
            var cell := VBoxContainer.new()
            cell.custom_minimum_size = Vector2(108, 100)
            cell.add_theme_constant_override("separation", 2)
            var icon := TextureRect.new()
            icon.custom_minimum_size = Vector2(108, 76)
            icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
            icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
            icon.texture = library.get_texture(gem_id, level, kind)
            cell.add_child(icon)
            var label := Label.new()
            label.text = "%s · L%d" % [String(gem_id), level]
            label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
            label.add_theme_font_size_override("font_size", 10)
            if icon.texture == null: label.text += " · MISSING"
            cell.add_child(label)
            grid.add_child(cell)
