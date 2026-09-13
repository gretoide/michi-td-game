class_name GameplayFoundation
extends RefCounted

const CATALOG_PATH := "res://data/gameplay/catalog.tres"

var catalog: Resource
var random: RandomSource
var load_result: CatalogLoadResult

func initialize(explicit_seed: int = -1) -> CatalogLoadResult:
	load_result = GameplayDataLoader.new().load_catalog(CATALOG_PATH)
	if not load_result.is_valid():
		return load_result
	var seed_value := SeedResolver.new().resolve(explicit_seed, load_result.catalog.globals.default_seed)
	random = SeededRandomSource.new(seed_value)
	catalog = load_result.catalog
	if OS.is_debug_build():
		print("Gameplay seed: %d" % seed_value)
	return load_result
