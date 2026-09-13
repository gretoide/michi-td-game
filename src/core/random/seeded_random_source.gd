class_name SeededRandomSource
extends "res://src/core/random/random_source.gd"

var seed_value: int
var _generator := RandomNumberGenerator.new()

func _init(value: int = 0) -> void:
	seed_value = value
	_generator.seed = value

func next_int(min_value: int, max_value: int) -> int:
	return _generator.randi_range(min_value, max_value)

func next_float() -> float:
	return _generator.randf()
