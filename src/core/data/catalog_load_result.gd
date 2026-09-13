class_name CatalogLoadResult
extends RefCounted

var catalog: Resource
var errors: Array[Dictionary] = []

func is_valid() -> bool:
	return catalog != null and errors.is_empty()

func add_error(code: String, path: String, message: String) -> void:
	errors.append({"code": code, "path": path, "message": message})
