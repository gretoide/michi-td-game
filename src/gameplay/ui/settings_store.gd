class_name SettingsStore
extends RefCounted

signal changed
const PATH := "user://game_settings.cfg"
var fullscreen := false
var music_volume := 100
var sfx_volume := 100
var music_enabled := true
var text_size := "normal"
var locale := "en"

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(PATH) == OK:
		fullscreen = bool(config.get_value("display", "fullscreen", false))
		music_volume = clampi(int(config.get_value("audio", "music", 100)), 0, 100)
		sfx_volume = clampi(int(config.get_value("audio", "sfx", 100)), 0, 100)
		music_enabled = bool(config.get_value("audio", "music_enabled", true))
		text_size = str(config.get_value("ui", "text_size", "normal"))
		if text_size not in ["small", "normal", "large"]: text_size = "normal"
		locale = str(config.get_value("ui", "locale", "en"))
		if locale not in ["en", "es"]: locale = "en"
	_apply_window()
	_apply_audio()

func save_settings() -> void:
	var config := ConfigFile.new(); config.set_value("display", "fullscreen", fullscreen)
	config.set_value("audio", "music", music_volume); config.set_value("audio", "sfx", sfx_volume); config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("ui", "text_size", text_size)
	config.set_value("ui", "locale", locale)
	config.save(PATH); _apply_audio(); changed.emit()

func set_fullscreen(value: bool) -> void:
	fullscreen = value; save_settings(); _apply_window(); changed.emit()

func set_music(value: int) -> void:
	music_volume = clampi(value, 0, 100); save_settings()

func set_music_enabled(value: bool) -> void:
	music_enabled = value; save_settings()

func set_sfx(value: int) -> void:
	sfx_volume = clampi(value, 0, 100); save_settings()

func set_text_size(value: String) -> void:
	text_size = value if value in ["small", "normal", "large"] else "normal"
	save_settings()

func set_locale(value: String) -> void:
	locale = value if value in ["en", "es"] else "en"
	save_settings()

func _apply_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)

func _apply_audio() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	var music_index := AudioServer.get_bus_index("Music")
	var sfx_index := AudioServer.get_bus_index("SFX")
	if music_index >= 0:
		AudioServer.set_bus_mute(music_index, not music_enabled)
		AudioServer.set_bus_volume_db(music_index, linear_to_db(maxf(music_volume / 100.0, 0.001)))
	if sfx_index >= 0:
		AudioServer.set_bus_mute(sfx_index, sfx_volume <= 0)
		AudioServer.set_bus_volume_db(sfx_index, linear_to_db(maxf(sfx_volume / 100.0, 0.001)))

func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
