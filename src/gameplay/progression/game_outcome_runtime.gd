class_name GameOutcomeRuntime
extends RefCounted

signal life_changed(value: int)
signal defeated
signal victorious
var max_life := 1000
var life := 1000
var score := 0
var finished := false

func reset() -> void:
	life = max_life; score = 0; finished = false; life_changed.emit(life)

func register_escape(attack: int) -> void:
	if finished: return
	life = maxi(0, life - maxi(attack, 0)); life_changed.emit(life)
	if life == 0:
		finished = true; defeated.emit()

func register_kill() -> void:
	if not finished: score += 1

func register_victory() -> void:
	if not finished:
		finished = true; victorious.emit()
