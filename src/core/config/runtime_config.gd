class_name RuntimeConfig
extends RefCounted

static func api_base_url() -> String:
    var configured := OS.get_environment("MICHI_API_URL").strip_edges()
    return configured if configured != "" else "http://127.0.0.1:3000/api/v1"
