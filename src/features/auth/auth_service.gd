class_name AuthService
extends Node

signal succeeded(session: Dictionary)
signal failed(message: String)
signal verification_required(email: String)
signal verification_succeeded(session: Dictionary)
signal resend_succeeded
signal restore_failed

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

func restore_session() -> void:
    if not SessionStore.restore_refresh_token():
        restore_failed.emit()
        return
    _action = "restore"
    _api.post_json("/auth/refresh", {"refreshToken": SessionStore.refresh_token})

func verify_email(email: String, code: String) -> void:
    _action = "verify"
    _api.post_json("/auth/verify-email", {"email": email, "code": code})

func resend_verification(email: String, password: String) -> void:
    _action = "resend"
    _api.post_json("/auth/resend-verification", {"email": email, "password": password})

func logout() -> void:
    if SessionStore.refresh_token != "":
        _api.post_json("/auth/logout", {"refreshToken": SessionStore.refresh_token})
    SessionStore.clear()

func _on_api_completed(success: bool, _status: int, data: Variant, error: String) -> void:
    if _action != "register" and _action != "login" and _action != "verify" and _action != "resend" and _action != "restore":
        return
    var action := _action
    _action = ""
    if success and action == "verify" and data is Dictionary and data.has("accessToken"):
        SessionStore.set_session(data)
        verification_succeeded.emit(data)
    elif success and data is Dictionary and data.has("accessToken"):
        SessionStore.set_session(data)
        if action == "restore":
            succeeded.emit(data)
        else:
            succeeded.emit(data)
    elif success and action == "register":
        verification_required.emit(str(data.get("email", "")))
    elif success and action == "resend":
        resend_succeeded.emit()
    else:
        if data is Dictionary and str(data.get("code", "")) == "EMAIL_NOT_VERIFIED":
            verification_required.emit(str(data.get("email", "")))
        else:
            if action == "restore":
                SessionStore.clear()
                restore_failed.emit()
            else:
                var prefix := "No se pudo completar la operación"
                if action == "register": prefix = "No se pudo registrar"
                elif action == "login": prefix = "No se pudo iniciar sesión"
                elif action == "verify": prefix = "No se pudo confirmar el código"
                elif action == "resend": prefix = "No se pudo reenviar el código"
                failed.emit(prefix + ": " + error)
