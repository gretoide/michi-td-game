class_name GameplayDataLoader
extends RefCounted

const M5ContentCatalogScript = preload("res://src/core/data/m5_content_catalog.gd")

func load_catalog(path: String) -> CatalogLoadResult:
	var result := CatalogLoadResult.new()
	if not ResourceLoader.exists(path):
		result.add_error("missing_file", path, "No existe el catálogo")
		return result
	var catalog := ResourceLoader.load(path) as Resource
	if catalog == null:
		result.add_error("invalid_resource", path, "El recurso no es un GameplayCatalog válido")
		return result
	# M5 replaces the bootstrap fixtures with the canonical, validated content
	# while keeping the .tres as the stable entry point for the runtime.
	M5ContentCatalogScript.expand(catalog)
	return GameplayCatalogValidator.new().validate(catalog)
