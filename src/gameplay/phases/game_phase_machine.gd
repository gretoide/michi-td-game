class_name GamePhaseMachine
extends RefCounted

signal phase_exited(phase: Phase)
signal phase_entered(phase: Phase)

enum Phase { CONSTRUCTION, COMBAT }
const CONSTRUCTION_ACTIONS := [&"place_gem", &"keep", &"combine", &"remove_stone", &"degrade", &"toggle_attack"]
const COMBAT_ACTIONS := [&"attack", &"stop"]

var phase := Phase.CONSTRUCTION
var wave_number := 1
var construction_resolved := false

func reset() -> void:
	phase = Phase.CONSTRUCTION; wave_number = 1; construction_resolved = false
	phase_entered.emit(phase)

func is_action_allowed(action: StringName) -> bool:
	return action in (CONSTRUCTION_ACTIONS if phase == Phase.CONSTRUCTION else COMBAT_ACTIONS)

func resolve_construction() -> bool:
	if phase != Phase.CONSTRUCTION: return false
	construction_resolved = true
	return _transition(Phase.COMBAT)

func resolve_combat() -> bool:
	if phase != Phase.COMBAT: return false
	wave_number += 1; construction_resolved = false
	return _transition(Phase.CONSTRUCTION)

func _transition(next: Phase) -> bool:
	phase_exited.emit(phase); phase = next; phase_entered.emit(phase); return true
