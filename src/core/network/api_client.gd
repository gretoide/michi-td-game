class_name ApiClient
extends Node

signal completed(success: bool, status: int, data: Variant, error: String)
signal request_started

var _request: HTTPRequest
var _base_url: String = RuntimeConfig.api_base_url()

func _ready() -> void:
    _request = HTTPRequest.new()
    add_child(_request)
    _request.request_completed.connect(_on_request_completed)

func get_json(path: String) -> void:
    _send(HTTPClient.METHOD_GET, path, {})

func post_json(path: String, payload: Dictionary) -> void:
    _send(HTTPClient.METHOD_POST, path, payload)

func _send(method: HTTPClient.Method, path: String, payload: Dictionary) -> void:
    if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
        completed.emit(false, 0, {}, "Ya hay una solicitud en curso")
        return
    var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
    var body := "" if payload.is_empty() else JSON.stringify(payload)
    request_started.emit()
    var error := _request.request(_base_url + path, headers, method, body)
    if error != OK:
        completed.emit(false, 0, {}, "No se pudo iniciar la solicitud")

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
    var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
    var data: Variant = parsed if parsed != null else {}
    var success := result == HTTPRequest.RESULT_SUCCESS and response_code >= 200 and response_code < 300
    var message := ""
    if not success:
        if data is Dictionary and data.has("message"):
            var api_message: Variant = data["message"]
            if api_message is Array:
                var parts := PackedStringArray()
                for item in api_message:
                    parts.append(str(item))
                message = "\n".join(parts)
            else:
                message = str(api_message)
        else:
            message = "No se pudo conectar con la API"
    completed.emit(success, response_code, data, message)
