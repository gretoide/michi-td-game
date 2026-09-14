class_name CommandCardModel
extends RefCounted

const HOTKEYS := ["Q","W","E","R","A","S","D","F","Z","X","C","V"]
var actions: Array[Dictionary] = []

func rebuild(runtime: GameRuntime, selection: SelectionState) -> void:
	actions.clear()
	var labels := ["Place Gem", "Select Gem", "Combine", "Degrade", "Remove Stone", "Attack", "Stop", "Recipes", "Keep Gem", "Debug", "Settings", "Restart"]
	for index in HOTKEYS.size():
		var enabled := true
		if index == 0: enabled = runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION and runtime.construction.placed_count() < 5
		if index in [1,2,3,4,8]: enabled = runtime.phases.phase == GamePhaseMachine.Phase.CONSTRUCTION and not selection.is_empty()
		var id: String = labels[index].to_lower().replace(" ", "_")
		actions.append({"id": id, "label": labels[index], "hotkey": HOTKEYS[index], "enabled": enabled, "visible": id not in ["place_gem", "select_gem", "attack", "stop", "debug", "settings"]})
