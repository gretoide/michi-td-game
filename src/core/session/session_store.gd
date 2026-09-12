extends Node

var access_token: String = ""
var refresh_token: String = ""
var user: Dictionary = {}

func set_session(session: Dictionary) -> void:
    access_token = str(session.get("accessToken", ""))
    refresh_token = str(session.get("refreshToken", ""))
    user = session.get("user", {}) as Dictionary
    persist_refresh_token()

func restore_refresh_token() -> bool:
    var config := ConfigFile.new()
    if config.load("user://session.cfg") != OK:
        return false
    refresh_token = str(config.get_value("session", "refresh_token", ""))
    return refresh_token != ""

func persist_refresh_token() -> void:
    if refresh_token.is_empty():
        return
    var config := ConfigFile.new()
    config.set_value("session", "refresh_token", refresh_token)
    config.save("user://session.cfg")

func clear() -> void:
    access_token = ""
    refresh_token = ""
    user = {}
    DirAccess.remove_absolute(ProjectSettings.globalize_path("user://session.cfg"))

func is_authenticated() -> bool:
    return access_token != "" and not user.is_empty()
