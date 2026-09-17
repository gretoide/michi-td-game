class_name VisualAssetConfig
extends Resource

@export_category("Cursores")
@export var cursor_normal: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/gauntlet_open.png")
@export var cursor_click: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/gauntlet_point.png")
@export var cursor_text: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/bracket_a_vertical.png")
@export var cursor_construction: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/tool_hammer.png")
@export var cursor_loader_1: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_empty.png")
@export var cursor_loader_2: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_CW_25.png")
@export var cursor_loader_3: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_CW_50.png")
@export var cursor_loader_4: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_CW_75.png")
@export var cursor_size := 28
@export var cursor_normal_hotspot := Vector2(2, 2)
@export var cursor_click_hotspot := Vector2(2, 2)
@export var cursor_text_hotspot := Vector2(8, 8)
@export var cursor_construction_hotspot := Vector2(1, 1)
@export var cursor_loader_hotspot := Vector2(10, 10)

@export_category("Iconos de acceso")
@export var alert_error: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/mark_exclamation.png")
@export var back_arrow: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/navigation_w.png")
@export var forward_arrow: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/navigation_w.png")
@export var password_eye_visible: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/look_c.png")
@export var password_eye_hidden: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/look_d.png")
@export var loader_hourglass_1: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_empty.png")
@export var loader_hourglass_2: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_CW_25.png")
@export var loader_hourglass_3: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_CW_50.png")
@export var loader_hourglass_4: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/progress_CW_75.png")
@export var login_loader: Texture2D = preload("res://assets/ui/loaders/login_cats_loader.png")

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
@export var tower_selection: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/mark_exclamation.png")
@export var zoom_plus: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/line_cross.png")
@export var zoom_minus: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/line_horizontal.png")
@export var zoom_reset: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/rotate_ccw.png")
@export var close: Texture2D = preload("res://assets/ui/icons/kenney_basic_double/cross_small.png")
