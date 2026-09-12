class_name AuthService
extends Node

signal succeeded(session: Dictionary)
signal failed(message: String)

var _api: ApiClient
var _action: String = ""

func setup(api: ApiClient) -> void:
    _api = api
    _api.completed.connect(_on_api_completed)

func register(alias: String, email: String, password: String) -> void:
    _action = "register"
    _api.post_json("/auth/register", {"alias": alias, "email": email, "password": password})

func login(email: String, password: String) -> void:
    _action = "login"
    _api.post_json("/auth/login", {"email": email, "password": password})

func logout() -> void:
    if SessionStore.refresh_token != "":
        _api.post_json("/auth/logout", {"refreshToken": SessionStore.refresh_token})
    SessionStore.clear()

func _on_api_completed(success: bool, _status: int, data: Variant, error: String) -> void:
    if _action != "register" and _action != "login":
        return
    var action := _action
    _action = ""
    if success and data is Dictionary and data.has("accessToken"):
        SessionStore.set_session(data)
        succeeded.emit(data)
    else:
        var prefix := "No se pudo registrar" if action == "register" else "No se pudo iniciar sesión"
        failed.emit(prefix + ": " + error)
