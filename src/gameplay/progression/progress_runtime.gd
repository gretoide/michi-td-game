class_name ProgressRuntime
extends RefCounted

signal changed(value: float)

var value := 50.0
var future_count_modifier := 0

func reset() -> void:
	value = 50.0; future_count_modifier = 0; changed.emit(value)

func on_kill(is_boss := false, is_final_boss := false) -> void:
	add(15.0 if is_final_boss else (10.0 if is_boss else 0.75))

func on_checkpoint(index: int, is_boss := false) -> void:
	var penalties := [0.0, 0.25, 0.5, 0.75, 1.0] if not is_boss else [0.0, 1.25, 2.5, 3.75, 5.0]
	if index >= 0 and index < penalties.size(): add(-penalties[index])

func on_final_checkpoint(is_boss := false) -> void:
	add(-10.0 if is_boss else -2.0)

func add(amount: float) -> void:
	value += amount
	while value >= 100.0:
		value -= 100.0; future_count_modifier += 1
	while value <= 0.0:
		value += 100.0; future_count_modifier -= 1
	changed.emit(value)
