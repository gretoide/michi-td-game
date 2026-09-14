class_name GameplayCatalog
extends Resource

@export var schema_version: int = 1
@export var globals: Resource
@export var gems: Array[Resource] = []
@export var recipes: Array[Resource] = []
@export var enemy_profiles: Array[Resource] = []
@export var waves: Array[Resource] = []

func gem_by_id(id: StringName) -> Resource:
	for gem in gems:
		if gem.id == id:
			return gem
	return null

func recipe_by_id(id: StringName) -> Resource:
	for recipe in recipes:
		if recipe.id == id:
			return recipe
	return null

func enemy_profile_by_id(id: StringName) -> Resource:
	for profile in enemy_profiles:
		if profile.id == id:
			return profile
	return null

func gem_definition_for_id(id: StringName) -> Resource:
	var basic := gem_by_id(id)
	if basic != null: return basic
	var recipe := recipe_by_id(id)
	if recipe == null: return null
	var definition := GemDefinition.new()
	definition.id = id
	definition.display_name = str(id).capitalize()
	definition.levels = [{"level": 1, "quality": "Upgrade", "range": recipe.range_units, "damage": recipe.damage, "attack_speed": recipe.attack_speed, "ability_ids": recipe.ability_ids}]
	return definition
