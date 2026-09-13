class_name GameplayCatalogValidator
extends RefCounted

func validate(catalog: Resource) -> CatalogLoadResult:
	var result := CatalogLoadResult.new()
	result.catalog = catalog
	if catalog == null:
		result.add_error("missing_catalog", "catalog", "GameplayCatalog no fue cargado")
		return result
	if catalog.schema_version != 1:
		result.add_error("schema_version", "catalog.schema_version", "Schema no soportado: %s" % catalog.schema_version)
	if catalog.globals == null:
		result.add_error("missing_required", "globals", "Falta la configuración global")
	else:
		if catalog.globals.projectile_speed <= 0.0:
			result.add_error("invalid_range", "globals.projectile_speed", "Debe ser mayor que cero")
		if catalog.globals.default_enemy_speed <= 0.0:
			result.add_error("invalid_range", "globals.default_enemy_speed", "Debe ser mayor que cero")
	_validate_gems(catalog, result)
	_validate_recipes(catalog, result)
	_validate_profiles(catalog, result)
	_validate_waves(catalog, result)
	return result

func _validate_gems(catalog: GameplayCatalog, result: CatalogLoadResult) -> void:
	var ids := {}
	for gem in catalog.gems:
		if gem == null or gem.id == StringName(""):
			result.add_error("missing_required", "gems", "Cada gema requiere un id")
			continue
		if ids.has(gem.id):
			result.add_error("duplicate_id", "gems.%s" % gem.id, "ID de gema duplicado")
		ids[gem.id] = true
		if gem.levels.is_empty():
			result.add_error("missing_required", "gems.%s.levels" % gem.id, "Debe existir al menos un nivel")
		for index in gem.levels.size():
			var level: Dictionary = gem.levels[index]
			for field in ["level", "damage", "range", "attack_speed"]:
				if not level.has(field):
					result.add_error("missing_required", "gems.%s.levels[%d].%s" % [gem.id, index, field], "Falta el campo requerido")
			if level.has("level") and int(level.level) < 1:
				result.add_error("invalid_range", "gems.%s.levels[%d].level" % [gem.id, index], "El nivel debe ser positivo")

func _validate_recipes(catalog: GameplayCatalog, result: CatalogLoadResult) -> void:
	var ids := {}
	for recipe in catalog.recipes:
		if recipe == null or recipe.id == StringName(""):
			result.add_error("missing_required", "recipes", "Cada receta requiere un id")
			continue
		if ids.has(recipe.id):
			result.add_error("duplicate_id", "recipes.%s" % recipe.id, "ID de receta duplicado")
		ids[recipe.id] = true
		if recipe.result_id == StringName(""):
			result.add_error("missing_required", "recipes.%s.result_id" % recipe.id, "Falta el resultado")
		elif catalog.gem_by_id(recipe.result_id) == null and catalog.recipe_by_id(recipe.result_id) == null:
			result.add_error("invalid_reference", "recipes.%s.result_id" % recipe.id, "Resultado inexistente")
		for index in recipe.ingredients.size():
			var ingredient: Dictionary = recipe.ingredients[index]
			if not ingredient.has("id") or not ingredient.has("level"):
				result.add_error("missing_required", "recipes.%s.ingredients[%d]" % [recipe.id, index], "Ingrediente requiere id y level")
			elif int(ingredient.level) < 1:
				result.add_error("invalid_range", "recipes.%s.ingredients[%d].level" % [recipe.id, index], "El nivel debe ser positivo")
			elif catalog.gem_by_id(StringName(ingredient.id)) == null and catalog.recipe_by_id(StringName(ingredient.id)) == null:
				result.add_error("invalid_reference", "recipes.%s.ingredients[%d].id" % [recipe.id, index], "Ingrediente inexistente")

func _validate_profiles(catalog: GameplayCatalog, result: CatalogLoadResult) -> void:
	var ids := {}
	for profile in catalog.enemy_profiles:
		if profile == null or profile.id == StringName(""):
			result.add_error("missing_required", "enemy_profiles", "Cada perfil requiere un id")
			continue
		if ids.has(profile.id):
			result.add_error("duplicate_id", "enemy_profiles.%s" % profile.id, "ID de perfil duplicado")
		ids[profile.id] = true
		if profile.hp <= 0.0 or profile.base_speed <= 0.0 or profile.attack < 0.0 or profile.xp_reward < 0:
			result.add_error("invalid_range", "enemy_profiles.%s" % profile.id, "HP, velocidad, attack y XP deben ser válidos")

func _validate_waves(catalog: GameplayCatalog, result: CatalogLoadResult) -> void:
	var numbers := {}
	for wave in catalog.waves:
		if wave == null:
			result.add_error("missing_required", "waves", "Cada wave requiere una definición")
			continue
		if numbers.has(wave.number):
			result.add_error("duplicate_id", "waves.%d" % wave.number, "Número de wave duplicado")
		numbers[wave.number] = true
		if wave.number < 1 or wave.number > 50:
			result.add_error("invalid_range", "waves.%d.number" % wave.number, "La wave debe estar entre 1 y 50")
		if wave.enemy_profile_id == StringName("") or catalog.enemy_profile_by_id(wave.enemy_profile_id) == null:
			result.add_error("invalid_reference", "waves.%d.enemy_profile_id" % wave.number, "Perfil enemigo inexistente")
		if wave.spawn_count <= 0 or wave.spawn_interval <= 0.0:
			result.add_error("invalid_range", "waves.%d" % wave.number, "Spawn count e intervalo deben ser positivos")
