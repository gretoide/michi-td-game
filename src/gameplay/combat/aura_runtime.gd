class_name AuraRuntime
extends RefCounted

var id: StringName
var source_id: StringName
var origin := Vector2.ZERO
var radius_units := 0.0
var effect: EffectRuntime
var affected: Dictionary = {}

func setup(value_id: StringName, value_source: StringName, value_origin: Vector2, value_radius: float, value_effect: EffectRuntime) -> void:
	id = value_id; source_id = value_source; origin = value_origin; radius_units = value_radius; effect = value_effect

func evaluate(targets: Array[EnemyRuntime], host_provider: Callable) -> void:
	var next: Dictionary = {}
	for target in targets:
		if target != null and target.is_alive() and origin.distance_to(target.position) <= radius_units:
			next[target.id] = true
			if not affected.has(target.id): host_provider.call(target, effect)
	affected = next
