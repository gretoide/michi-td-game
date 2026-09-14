class_name SelectionState
extends RefCounted

signal changed

enum Kind { NONE, GEM, TOWER, ENEMY, STONE }
var kind := Kind.NONE
var value: Variant = null

func select(next_kind: Kind, next_value: Variant) -> void:
	kind = next_kind; value = next_value; changed.emit()

func clear() -> void:
	kind = Kind.NONE; value = null; changed.emit()

func is_empty() -> bool:
	return kind == Kind.NONE or value == null

