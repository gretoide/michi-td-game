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
