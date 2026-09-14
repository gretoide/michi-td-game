class_name SupportSkillRuntime
extends RefCounted

var id: StringName
var level := 1
var max_level := 4
var cost := 0
var cooldown := 0.0

func setup(value_id: StringName, value_level := 1, value_cost := 0, value_cooldown := 0.0) -> bool:
	if value_level < 1 or value_level > max_level: return false
	id = value_id; level = value_level; cost = maxi(value_cost, 0); cooldown = maxf(value_cooldown, 0.0); return true
