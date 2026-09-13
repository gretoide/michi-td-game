class_name FoundationDataTest
extends RefCounted

const Loader = preload("res://src/core/data/gameplay_data_loader.gd")
const Catalog = preload("res://src/core/data/model/gameplay_catalog.gd")
const Globals = preload("res://src/core/data/model/global_config.gd")
const Gem = preload("res://src/core/data/model/gem_definition.gd")
const Validator = preload("res://src/core/data/gameplay_catalog_validator.gd")

func run(suite: RefCounted) -> void:
	var loaded := Loader.new().load_catalog("res://data/gameplay/catalog.tres")
	suite.expect(loaded.is_valid(), "El catálogo bootstrap debe ser válido: %s" % str(loaded.errors))
	suite.expect(loaded.catalog != null and loaded.catalog.gem_by_id(&"amethyst") != null, "Debe cargar la gema bootstrap")
	suite.expect(loaded.catalog != null and loaded.catalog.recipe_by_id(&"silver") != null, "Debe cargar la receta bootstrap")
	suite.expect(loaded.catalog != null and loaded.catalog.enemy_profile_by_id(&"frenzied_pig") != null, "Debe cargar el perfil bootstrap")
	var missing := Loader.new().load_catalog("res://data/gameplay/missing.tres")
	suite.expect(not missing.is_valid() and missing.errors[0].code == "missing_file", "Un archivo ausente debe producir error accionable")
	var duplicate := Catalog.new()
	duplicate.globals = Globals.new()
	var gem_a := Gem.new(); gem_a.id = &"duplicate"; gem_a.levels = [{"level": 1, "damage": 1.0, "range": 1.0, "attack_speed": 1.0}]
	var gem_b := Gem.new(); gem_b.id = &"duplicate"; gem_b.levels = gem_a.levels
	duplicate.gems = [gem_a, gem_b]
	var invalid := Validator.new().validate(duplicate)
	suite.expect(not invalid.is_valid(), "IDs duplicados deben invalidar el catálogo")
