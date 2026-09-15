class_name PlayerProgressionRuntime
extends RefCounted

signal changed(xp: int, quality_level: int)
var xp := 0
var quality_level := 1
var thresholds: Array[int] = [2400, 6400, 11600, 17600]
const MAX_LEVEL := 5

func reset() -> void:
	xp = 0; quality_level = 1; changed.emit(xp, quality_level)

func add_xp(amount: int) -> void:
	if amount <= 0: return
	xp = mini(17600, xp + amount)
	quality_level = 1
	for threshold in thresholds:
		if xp >= threshold: quality_level = mini(5, quality_level + 1)
	changed.emit(xp, quality_level)

func current_level_threshold() -> int:
	if quality_level <= 1: return 0
	return thresholds[mini(quality_level - 2, thresholds.size() - 1)]

func next_level_threshold() -> int:
	if quality_level >= MAX_LEVEL: return thresholds[thresholds.size() - 1]
	return thresholds[mini(quality_level - 1, thresholds.size() - 1)]

func progress_ratio() -> float:
	if quality_level >= MAX_LEVEL: return 1.0
	var span := next_level_threshold() - current_level_threshold()
	if span <= 0: return 0.0
	return clampf(float(xp - current_level_threshold()) / float(span), 0.0, 1.0)
