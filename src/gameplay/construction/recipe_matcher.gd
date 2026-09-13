class_name RecipeMatcher
extends RefCounted

func find_matches(recipes: Array, gems: Array, include_secret := true) -> Array:
	var matches: Array = []
	for recipe in recipes:
		if recipe == null or (not include_secret and recipe.secret):
			continue
		var selection := match_recipe(recipe, gems)
		if not selection.is_empty():
			matches.append({"recipe": recipe, "gems": selection})
	return matches

func match_recipe(recipe: RecipeDefinition, gems: Array) -> Array:
	var available := gems.duplicate()
	var selected: Array = []
	for ingredient in recipe.ingredients:
		var found := -1
		for index in available.size():
			var gem: GemInstance = available[index]
			if gem.id == StringName(ingredient.id) and gem.level == int(ingredient.level):
				found = index
				break
		if found < 0:
			return []
		selected.append(available[found])
		available.remove_at(found)
	return selected

func visible_recipes(recipes: Array) -> Array:
	var visible: Array = []
	for recipe in recipes:
		if recipe != null and not recipe.secret:
			visible.append(recipe)
	return visible

