class_name EconomyRuntime
extends RefCounted

signal changed(gold: int)
var gold := 0
var _resolved: Dictionary = {}

func reset() -> void:
	gold = 0; _resolved.clear(); changed.emit(gold)

func reward(enemy_id: int, amount: int, resolution: StringName) -> bool:
	if resolution != &"death" or _resolved.has(enemy_id): return false
	_resolved[enemy_id] = true; gold += maxi(amount, 0); changed.emit(gold); return true

func spend(amount: int) -> bool:
	if amount < 0 or gold < amount: return false
	gold -= amount; changed.emit(gold); return true
