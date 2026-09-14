class_name PlayerProgressionRuntime
extends RefCounted

signal changed(xp: int, quality_level: int)
var xp := 0
var quality_level := 1
var thresholds: Array[int] = [2400, 6400, 11600, 17600]

func reset() -> void:
	xp = 0; quality_level = 1; changed.emit(xp, quality_level)

func add_xp(amount: int) -> void:
	if amount <= 0: return
	xp = mini(17600, xp + amount)
	quality_level = 1
	for threshold in thresholds:
		if xp >= threshold: quality_level = mini(5, quality_level + 1)
	changed.emit(xp, quality_level)
