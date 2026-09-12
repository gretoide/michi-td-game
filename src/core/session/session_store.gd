extends Node

var access_token: String = ""
var refresh_token: String = ""
var user: Dictionary = {}

func set_session(session: Dictionary) -> void:
    access_token = str(session.get("accessToken", ""))
    refresh_token = str(session.get("refreshToken", ""))
    user = session.get("user", {}) as Dictionary

func clear() -> void:
    access_token = ""
    refresh_token = ""
    user = {}

func is_authenticated() -> bool:
    return access_token != "" and not user.is_empty()
