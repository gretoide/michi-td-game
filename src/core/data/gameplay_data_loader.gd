class_name GameplayDataLoader
extends RefCounted

func load_catalog(path: String) -> CatalogLoadResult:
	var result := CatalogLoadResult.new()
	if not ResourceLoader.exists(path):
		result.add_error("missing_file", path, "No existe el catálogo")
		return result
	var catalog := ResourceLoader.load(path) as Resource
	if catalog == null:
		result.add_error("invalid_resource", path, "El recurso no es un GameplayCatalog válido")
		return result
	return GameplayCatalogValidator.new().validate(catalog)
