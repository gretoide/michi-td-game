class_name StoneInstance
extends RefCounted

var cell := Vector2i(-1, -1)
var source_gem_id: StringName
var round_id := 0

func _init(source_id: StringName = &"", source_cell := Vector2i(-1, -1), source_round := 0) -> void:
	source_gem_id = source_id
	cell = source_cell
	round_id = source_round
