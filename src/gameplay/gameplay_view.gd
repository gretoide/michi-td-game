class_name GameplayView
extends Control

var runtime: GameRuntime
var phase_label: Label
var wave_label: Label

func setup(value: GameRuntime) -> void:
	runtime = value
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new(); background.color = Color("152238"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var map_view := MapDebugView.new(); map_view.runtime = runtime; map_view.set_anchors_preset(Control.PRESET_FULL_RECT); map_view.offset_left = 40; map_view.offset_top = 70; map_view.offset_right = -40; map_view.offset_bottom = -70; background.add_child(map_view)
	var hud := HBoxContainer.new(); hud.set_anchors_preset(Control.PRESET_TOP_WIDE); hud.offset_left = 24; hud.offset_top = 16; hud.offset_right = -24; hud.offset_bottom = 58; background.add_child(hud)
	phase_label = Label.new(); phase_label.text = LocalizationService.tr_key("game.phase.construction"); phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; hud.add_child(phase_label)
	wave_label = Label.new(); wave_label.text = LocalizationService.tr_key("game.wave", {"number": 1}); hud.add_child(wave_label)
	var locale := LocaleSelector.new(); locale.custom_minimum_size = Vector2(82,38); locale.setup(); hud.add_child(locale)
	var pause := Button.new(); pause.text = "Ⅱ"; pause.tooltip_text = LocalizationService.tr_key("game.pause"); pause.pressed.connect(func(): get_tree().paused = not get_tree().paused); pause.process_mode = Node.PROCESS_MODE_ALWAYS; hud.add_child(pause)
	runtime.phases.phase_entered.connect(_on_phase)
	LocalizationService.locale_changed.connect(func(_locale: String): _on_phase(runtime.phases.phase))

func _on_phase(value: GamePhaseMachine.Phase) -> void:
	phase_label.text = LocalizationService.tr_key("game.phase.construction" if value == GamePhaseMachine.Phase.CONSTRUCTION else "game.phase.combat")
	wave_label.text = LocalizationService.tr_key("game.wave", {"number": runtime.phases.wave_number})

class MapDebugView extends Control:
	var runtime: GameRuntime
	func _draw() -> void:
		if runtime == null: return
		var area := get_rect().size
		var scale_value := minf(area.x, area.y) / 36.0
		for x in range(37): draw_line(Vector2(x * scale_value, 0), Vector2(x * scale_value, 36 * scale_value), Color(1,1,1,0.12))
		for y in range(37): draw_line(Vector2(0, y * scale_value), Vector2(36 * scale_value, y * scale_value), Color(1,1,1,0.12))
		var points := runtime.map.ordered_waypoints()
		for index in range(points.size()):
			var point := (Vector2(points[index]) + Vector2.ONE * 0.5) * scale_value
			draw_circle(point, 7.0, Color("65d6a6") if index > 0 and index < points.size() - 1 else Color("f2c14e"))
