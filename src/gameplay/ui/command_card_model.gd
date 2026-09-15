class_name CommandCardModel
extends RefCounted

const HOTKEYS := ["Q","W","E","R","A","S","D","F","Z","X","C","V"]
var actions: Array[Dictionary] = []

static func can_open_gem_context_popup(runtime: GameRuntime, gem: GemInstance) -> bool:
	if runtime == null or gem == null: return false
	if runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
		return runtime.construction.placed_count() == ConstructionRuntime.MAX_PLACEMENTS
	return true

func rebuild(runtime: GameRuntime, selection: SelectionState) -> void:
	actions.clear()
	var labels := ["Place Gem", "Select Gem", "Combine", "Degrade", "Remove Stone", "Attack", "Stop", "Recipes", "Keep Gem", "Debug", "Settings", "Restart"]
	for index in HOTKEYS.size():
		var id: String = labels[index].to_lower().replace(" ", "_")
		var construction := runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION
		var selected_gem := selection.kind == SelectionState.Kind.GEM and not selection.is_empty()
		var selected_stone := selection.kind == SelectionState.Kind.STONE and not selection.is_empty()
		var selected_tower := selection.kind == SelectionState.Kind.TOWER and not selection.is_empty()
		var selected_combination_gem: GemInstance = selection.value if selected_gem else (selection.value.gem if selected_tower and selection.value.gem != null else null)
		var can_combine := selected_combination_gem != null and not runtime.construction.contextual_combinations(selected_combination_gem).is_empty()
		var can_degrade: bool = selected_gem and selection.value.quality > GemInstance.Quality.CHIPPED
		var enabled := true
		var visible := false
		match id:
			"place_gem": visible = construction and runtime.construction.placed_count() < ConstructionRuntime.MAX_PLACEMENTS; enabled = visible
			"combine": visible = construction and can_combine; enabled = visible
			"degrade": visible = construction and can_degrade; enabled = visible
			"remove_stone": visible = selected_stone; enabled = visible
			"attack": visible = not construction and selected_tower; enabled = visible
			"stop": visible = not construction and selected_tower; enabled = visible
			"keep_gem": visible = construction and selected_gem and runtime.construction.placed_count() == ConstructionRuntime.MAX_PLACEMENTS; enabled = visible
			_: enabled = false
		actions.append({"id": id, "label": labels[index], "hotkey": HOTKEYS[index], "enabled": enabled, "visible": visible})
