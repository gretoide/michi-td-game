class_name ConstructionRuntime
extends RefCounted

signal gem_placed(gem: GemInstance)
signal placement_rejected(code: StringName, cell: Vector2i)
signal construction_changed(placed_count: int, total: int)
signal stone_created(stone: StoneInstance)
signal construction_finalized(result: GemInstance)
signal combination_completed(recipe_id: StringName, result: GemInstance)
signal selection_changed(gem: GemInstance)
signal stone_selected(cell: Vector2i)
signal gem_pool_changed

const MAX_PLACEMENTS := 5
var grid: GridModel
var pathfinder: GroundPathfinder
var map: MapLayout
var phases: GamePhaseMachine
var generator: GemGenerator
var recipes: Array = []
var matcher := RecipeMatcher.new()
var mvp := MvpState.new()
var current_gems: Array[GemInstance] = []
var available_gems: Array[GemInstance] = []
var selected_gem: GemInstance
var board_gems: Array[GemInstance] = []
var stones: Dictionary = {}
var selected_result: GemInstance
var selected_board_gem: GemInstance
var selected_stone_cell := Vector2i(-1, -1)
var round_id := 1

func setup(value_grid: GridModel, value_pathfinder: GroundPathfinder, value_phases: GamePhaseMachine, value_generator: GemGenerator, value_recipes: Array = [], value_map: MapLayout = null) -> void:
	grid = value_grid; pathfinder = value_pathfinder; phases = value_phases; generator = value_generator; recipes = value_recipes; map = value_map
	if generator != null:
		generator.reset_round(round_id)

func begin_round(value := 1) -> void:
	round_id = value
	current_gems.clear(); available_gems.clear(); selected_gem = null; selected_board_gem = null; selected_result = null; selected_stone_cell = Vector2i(-1, -1)
	if generator != null: generator.reset_round(round_id)
	construction_changed.emit(0, MAX_PLACEMENTS)
	gem_pool_changed.emit()

func ensure_gem_pool(player_level := 1) -> void:
	if generator == null or not available_gems.is_empty(): return
	for _i in range(MAX_PLACEMENTS):
		var gem := generator.generate(player_level)
		if gem != null: available_gems.append(gem)
	if not available_gems.is_empty():
		selected_gem = available_gems[0]
	gem_pool_changed.emit()

func select_available(index: int) -> GemInstance:
	if index < 0 or index >= available_gems.size(): return null
	selected_gem = available_gems[index]
	gem_pool_changed.emit()
	return selected_gem

func place_selected(cell: Vector2i) -> GemInstance:
	if selected_gem == null:
		placement_rejected.emit(&"no_gem_selected", cell); return null
	var gem := selected_gem
	var placed := _place_existing(gem, cell)
	if placed != null:
		available_gems.erase(gem)
		selected_gem = available_gems[0] if not available_gems.is_empty() else null
		gem_pool_changed.emit()
	return placed

func placed_count() -> int:
	return current_gems.size()

func gem_at_cell(cell: Vector2i) -> GemInstance:
	for gem: GemInstance in current_gems:
		if gem.cell == cell: return gem
	return null

func select_board_gem(cell: Vector2i) -> GemInstance:
	if phases == null or phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or placed_count() != MAX_PLACEMENTS:
		return null
	var gem := gem_at_cell(cell)
	if gem == null: return null
	selected_board_gem = gem
	selection_changed.emit(gem)
	return gem

func select_stone(cell: Vector2i) -> bool:
	if phases == null or phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or not stones.has(cell): return false
	selected_stone_cell = cell; stone_selected.emit(cell); return true

func can_place() -> bool:
	return phases != null and phases.phase == GamePhaseMachine.Phase.CONSTRUCTION and placed_count() < MAX_PLACEMENTS

func place_gem(cell: Vector2i, player_level := 1) -> GemInstance:
	if not can_place():
		placement_rejected.emit(&"phase_or_limit", cell); return null
	# Validate the requested cell and path before consuming one of the round's
	# five generated gems. Invalid placement must be side-effect free.
	var code := _placement_error(cell)
	if code != &"":
		placement_rejected.emit(code, cell); return null
	if not grid.occupy(cell):
		placement_rejected.emit(&"occupied", cell); return null
	var blocks_path := pathfinder.find_route(_map_for_path()).is_empty()
	grid.release(cell)
	if blocks_path:
		placement_rejected.emit(&"blocks_ground_path", cell); return null
	var gem := generator.generate(player_level) if generator != null else null
	return _place_existing(gem, cell)

func place_existing(gem: GemInstance, cell: Vector2i) -> GemInstance:
	if not can_place():
		placement_rejected.emit(&"phase_or_limit", cell); return null
	return _place_existing(gem, cell)

func _place_existing(gem: GemInstance, cell: Vector2i) -> GemInstance:
	if gem == null:
		placement_rejected.emit(&"generation_limit", cell); return null
	var code := _placement_error(cell)
	if code != &"":
		placement_rejected.emit(code, cell); return null
	if not grid.occupy(cell):
		placement_rejected.emit(&"occupied", cell); return null
	if pathfinder.find_route(_map_for_path()).is_empty():
		grid.release(cell); placement_rejected.emit(&"blocks_ground_path", cell); return null
	gem.cell = cell; gem.round_id = round_id
	current_gems.append(gem); board_gems.append(gem)
	gem_placed.emit(gem); construction_changed.emit(placed_count(), MAX_PLACEMENTS)
	return gem

func _placement_error(cell: Vector2i) -> StringName:
	if not grid.is_in_bounds(cell): return &"out_of_bounds"
	if grid.is_reserved(cell): return &"reserved"
	if not grid.is_walkable(cell): return &"occupied"
	return &""

func keep(gem: GemInstance) -> bool:
	if gem == null or gem not in current_gems or placed_count() != MAX_PLACEMENTS:
		return false
	selected_board_gem = gem
	return _finalize_current(gem)

func remove_stone(cell: Vector2i) -> bool:
	if phases == null or not phases.is_action_allowed(&"remove_stone") or not stones.has(cell):
		return false
	stones.erase(cell)
	selected_stone_cell = Vector2i(-1, -1)
	return grid.release(cell)

func degrade(gem: GemInstance) -> GemInstance:
	if phases == null or not phases.is_action_allowed(&"degrade") or gem == null or gem not in current_gems or placed_count() != MAX_PLACEMENTS:
		return null
	if gem.quality <= GemInstance.Quality.CHIPPED:
		return null
	gem.level = maxi(1, gem.level - 1)
	gem.quality = (gem.quality - 1) as GemInstance.Quality
	_finalize_current(gem)
	return gem

func basic_combinations() -> Array:
	if placed_count() != MAX_PLACEMENTS: return []
	var grouped := {}
	for gem in current_gems.duplicate():
		var key := "%s:%d" % [gem.id, gem.level]
		if not grouped.has(key): grouped[key] = []
		grouped[key].append(gem)
	var result: Array = []
	for key in grouped:
		var group: Array = grouped[key]
		if group.size() >= 4: result.append({"count": 4, "gems": group.slice(0, 4)})
		elif group.size() >= 2: result.append({"count": 2, "gems": group.slice(0, 2)})
	return result

func combine_basic(selected: GemInstance, count: int) -> GemInstance:
	if selected == null or placed_count() != MAX_PLACEMENTS or count not in [2, 4]: return null
	selected_board_gem = selected
	var candidates: Array = []
	for gem in current_gems:
		if gem.id == selected.id and gem.level == selected.level: candidates.append(gem)
	if candidates.size() < count: return null
	var result := selected.clone()
	result.level = mini(7, selected.level + (1 if count == 2 else 2))
	result.quality = _quality_for_level(result.level)
	for gem in candidates:
		if gem != selected: _make_stone(gem)
	return _replace_and_finalize(selected, result)

func find_one_shot_matches() -> Array:
	if phases == null or phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or placed_count() != MAX_PLACEMENTS: return []
	return matcher.find_matches(recipes, current_gems, true)

func find_advanced_matches() -> Array:
	if phases == null or phases.phase != GamePhaseMachine.Phase.COMBAT: return []
	return matcher.find_matches(recipes, board_gems, true)

func execute_recipe(recipe: RecipeDefinition, selected: GemInstance, one_shot := false) -> GemInstance:
	if recipe == null or selected == null: return null
	if one_shot:
		if phases.phase != GamePhaseMachine.Phase.CONSTRUCTION or placed_count() != MAX_PLACEMENTS: return null
	else:
		if phases.phase != GamePhaseMachine.Phase.COMBAT: return null
	var scope := current_gems if one_shot else board_gems
	var ingredients := matcher.match_recipe(recipe, scope)
	if ingredients.is_empty() or selected not in ingredients: return null
	var result := GemInstance.new(recipe.result_id, 1, GemInstance.Quality.CHIPPED)
	result.cell = selected.cell; result.mvp_level = 0 if one_shot else MvpState.transfer_mvp(ingredients)
	for gem in ingredients:
		if gem != selected: _make_stone(gem)
	if one_shot:
		_replace_and_finalize(selected, result)
	else:
		_replace_board_gem(selected, result)
	combination_completed.emit(recipe.id, result)
	return result

func _finalize_current(result: GemInstance) -> bool:
	for gem in current_gems.duplicate():
		if gem != result: _make_stone(gem)
	selected_result = result
	if phases != null and phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
		phases.resolve_construction()
	construction_finalized.emit(result)
	return true

func _replace_and_finalize(previous: GemInstance, result: GemInstance) -> GemInstance:
	_replace_board_gem(previous, result)
	current_gems.erase(previous); current_gems.append(result)
	_finalize_current(result)
	return result

func _replace_board_gem(previous: GemInstance, result: GemInstance) -> void:
	var index := board_gems.find(previous)
	if index >= 0: board_gems[index] = result

func _make_stone(gem: GemInstance) -> void:
	if gem == null: return
	current_gems.erase(gem); board_gems.erase(gem)
	var stone := StoneInstance.new(gem.id, gem.cell, gem.round_id)
	stones[stone.cell] = stone; stone_created.emit(stone)

func _quality_for_level(value: int) -> GemInstance.Quality:
	return GemInstance.Quality.IMPERIAL if value == 6 else (GemInstance.Quality.ROYAL if value >= 7 else value as GemInstance.Quality)

func _map_for_path() -> MapLayout:
	return map
