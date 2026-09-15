class_name GemAssetLibrary
extends RefCounted

enum AssetKind { GEM, TOWER }

const GEM_ATLAS_PATH := "res://assets/gems/base/gemas_base_atlas.png"
const TOWER_ATLAS_PATH := "res://assets/towers/base/torres_base_atlas.png"
const TOWER_VISIBLE_CELLS := 1.4175
const STONE_VISIBLE_CELLS := 0.9
const GEM_SPRITE_CELLS := 3.05
const TOWER_BASE_CELL_Y := 0.75
const TOWER_PEDESTAL_BAND_RATIO := 0.25
const GRID_COLUMNS := 8
const GRID_ROWS := 7
const BASE_GEM_IDS: Array[StringName] = [
    &"amethyst", &"aquamarine", &"diamond", &"emerald",
    &"opal", &"ruby", &"sapphire", &"topaz"
]

var _atlas_cache: Dictionary = {}
var _texture_cache: Dictionary = {}
var _atlas_image_cache: Dictionary = {}
var _tower_metrics_cache: Dictionary = {}

func get_gem_texture(gem_id: StringName, level: int) -> Texture2D:
    return get_texture(gem_id, level, AssetKind.GEM)

func get_tower_texture(gem_id: StringName, level: int) -> Texture2D:
    return get_texture(gem_id, level, AssetKind.TOWER)

func get_tower_visual_anchor(gem_id: StringName, level: int) -> Vector2:
    return _tower_visual_metrics(gem_id, level).get("anchor", Vector2(0.5, 0.5)) as Vector2

func get_tower_visible_fraction(gem_id: StringName, level: int) -> Vector2:
    return _tower_visual_metrics(gem_id, level).get("visible_fraction", Vector2.ONE) as Vector2

func _tower_visual_metrics(gem_id: StringName, level: int) -> Dictionary:
    if not has_base_asset(gem_id, level): return {"anchor": Vector2(0.5, 0.5), "visible_fraction": Vector2.ONE}
    var key := "%s:%d" % [String(gem_id), level]
    if _tower_metrics_cache.has(key): return _tower_metrics_cache[key] as Dictionary
    var image := _load_atlas_image(AssetKind.TOWER)
    if image == null or image.is_empty(): return {"anchor": Vector2(0.5, 0.5), "visible_fraction": Vector2.ONE}
    var column := BASE_GEM_IDS.find(gem_id)
    var row := level - 1
    var cell_width := image.get_width() / GRID_COLUMNS
    var cell_height := image.get_height() / GRID_ROWS
    var min_x := cell_width
    var max_x := -1
    var min_y := cell_height
    var max_y := -1
    for y in range(cell_height):
        for x in range(cell_width):
            if image.get_pixel(column * cell_width + x, row * cell_height + y).a <= 0.05: continue
            min_x = mini(min_x, x)
            max_x = maxi(max_x, x)
            min_y = mini(min_y, y)
            max_y = maxi(max_y, y)
    var anchor := Vector2(0.5, 0.5)
    var visible_fraction := Vector2.ONE
    if max_x >= min_x and max_y >= min_y:
        var visible_height := max_y - min_y + 1
        var pedestal_height := maxi(1, int(ceil(float(visible_height) * TOWER_PEDESTAL_BAND_RATIO)))
        var pedestal_start_y := maxi(min_y, max_y - pedestal_height + 1)
        var pedestal_min_x := cell_width
        var pedestal_max_x := -1
        for y in range(pedestal_start_y, max_y + 1):
            for x in range(cell_width):
                if image.get_pixel(column * cell_width + x, row * cell_height + y).a <= 0.05: continue
                pedestal_min_x = mini(pedestal_min_x, x)
                pedestal_max_x = maxi(pedestal_max_x, x)
        if pedestal_max_x >= pedestal_min_x:
            anchor.x = (float(pedestal_min_x) + float(pedestal_max_x + 1)) * 0.5 / float(cell_width)
        else:
            anchor.x = (float(min_x) + float(max_x + 1)) * 0.5 / float(cell_width)
        anchor.y = float(max_y + 1) / float(cell_height)
        visible_fraction = Vector2(float(max_x - min_x + 1) / float(cell_width), float(max_y - min_y + 1) / float(cell_height))
    var metrics := {"anchor": anchor, "visible_fraction": visible_fraction}
    _tower_metrics_cache[key] = metrics
    return metrics

func get_texture(gem_id: StringName, level: int, asset_kind: AssetKind) -> Texture2D:
    if not has_base_asset(gem_id, level): return null
    var key := "%d:%s:%d" % [int(asset_kind), String(gem_id), level]
    if _texture_cache.has(key): return _texture_cache[key] as Texture2D
    var atlas := _load_atlas(asset_kind)
    if atlas == null or atlas.get_width() % GRID_COLUMNS != 0 or atlas.get_height() % GRID_ROWS != 0:
        return null
    var column := BASE_GEM_IDS.find(gem_id)
    var row := level - 1
    var cell_width := atlas.get_width() / GRID_COLUMNS
    var cell_height := atlas.get_height() / GRID_ROWS
    var region := AtlasTexture.new()
    region.atlas = atlas
    region.region = Rect2(column * cell_width, row * cell_height, cell_width, cell_height)
    region.filter_clip = true
    _texture_cache[key] = region
    return region

func has_base_asset(gem_id: StringName, level: int) -> bool:
    return BASE_GEM_IDS.has(gem_id) and level >= 1 and level <= GRID_ROWS

func validate_base_assets() -> PackedStringArray:
    var errors := PackedStringArray()
    for gem_id in BASE_GEM_IDS:
        for level in range(1, GRID_ROWS + 1):
            if get_gem_texture(gem_id, level) == null:
                errors.append("Missing gem asset %s level %d" % [gem_id, level])
            if get_tower_texture(gem_id, level) == null:
                errors.append("Missing tower asset %s level %d" % [gem_id, level])
    return errors

func atlas_dimensions(asset_kind: AssetKind) -> Vector2i:
    var atlas := _load_atlas(asset_kind)
    return Vector2i.ZERO if atlas == null else Vector2i(atlas.get_width(), atlas.get_height())

func _load_atlas(asset_kind: AssetKind) -> Texture2D:
    var path := TOWER_ATLAS_PATH if asset_kind == AssetKind.TOWER else GEM_ATLAS_PATH
    if _atlas_cache.has(path): return _atlas_cache[path] as Texture2D
    var atlas := load(path) as Texture2D
    if atlas != null: _atlas_cache[path] = atlas
    return atlas

func _load_atlas_image(asset_kind: AssetKind) -> Image:
    var path := TOWER_ATLAS_PATH if asset_kind == AssetKind.TOWER else GEM_ATLAS_PATH
    if _atlas_image_cache.has(path): return _atlas_image_cache[path] as Image
    var atlas := _load_atlas(asset_kind)
    var image := atlas.get_image() if atlas != null else null
    if image != null: _atlas_image_cache[path] = image
    return image
