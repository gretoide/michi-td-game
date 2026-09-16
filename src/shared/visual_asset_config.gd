class_name VisualAssetConfig
extends Resource

@export_category("Cursores")
@export var cursor_normal: Texture2D = preload("res://assets/ui/cursors/cursor_normal.png")
@export var cursor_click: Texture2D = preload("res://assets/ui/cursors/cursor_click.png")
@export var cursor_text: Texture2D = preload("res://assets/ui/cursors/tile_0140.png")
@export var cursor_construction: Texture2D = preload("res://assets/ui/cursors/tile_0108.png")
@export var cursor_loader_1: Texture2D = preload("res://assets/ui/cursors/loader_cursor_1.png")
@export var cursor_loader_2: Texture2D = preload("res://assets/ui/cursors/loader_cursor_2.png")
@export var cursor_size := 20
@export var cursor_normal_hotspot := Vector2(2, 2)
@export var cursor_click_hotspot := Vector2(2, 2)
@export var cursor_text_hotspot := Vector2(8, 8)
@export var cursor_construction_hotspot := Vector2(1, 1)
@export var cursor_loader_hotspot := Vector2(10, 10)

@export_category("Iconos de acceso")
@export var alert_error: Texture2D = preload("res://assets/ui/icons/alert_error.png")
@export var back_arrow: Texture2D = preload("res://assets/ui/cursors/back_arrow.png")
@export var password_eye_visible: Texture2D = preload("res://assets/ui/cursors/password_eye_visible.png")
@export var password_eye_hidden: Texture2D = preload("res://assets/ui/cursors/password_eye_hidden.png")
@export var loader_hourglass_1: Texture2D = preload("res://assets/ui/cursors/loader_hourglass_1.png")
@export var loader_hourglass_2: Texture2D = preload("res://assets/ui/cursors/loader_hourglass_2.png")
@export var loader_hourglass_3: Texture2D = preload("res://assets/ui/cursors/loader_hourglass_3.png")

@export_category("Iconos del juego")
@export var hud_life: Texture2D = preload("res://assets/ui/icons/gameplay/life.png")
@export var hud_gold: Texture2D = preload("res://assets/ui/icons/gameplay/gold.png")
# The original HUD did not ship a dedicated progress icon. Leave it empty by
# default so it can be assigned from the Inspector when desired.
@export var hud_progress: Texture2D
@export var settings: Texture2D = preload("res://assets/ui/icons/gameplay/settings.png")
@export var recipes: Texture2D = preload("res://assets/ui/icons/gameplay/recipes.png")
@export var help: Texture2D = preload("res://assets/ui/icons/gameplay/help.png")
@export var main_menu: Texture2D = preload("res://assets/ui/icons/gameplay/main_menu.png")
@export var logout: Texture2D = preload("res://assets/ui/icons/gameplay/logout.png")
@export var music_enabled: Texture2D = preload("res://assets/ui/icons/music_enabled.png")
@export var music_disabled: Texture2D = preload("res://assets/ui/icons/music_disabled.png")
@export var close: Texture2D = preload("res://assets/ui/cursors/tile_0016.png")
