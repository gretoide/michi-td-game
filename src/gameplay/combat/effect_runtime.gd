class_name EffectRuntime
extends RefCounted

enum Hook { PRE_DAMAGE, POST_IMPACT, TICK, AURA }
var effect_id: StringName
var damage_type := DamagePipeline.DamageType.MAGIC
var effect_school: StringName = &"Magical"
var is_debuff := false
var source_id: StringName
var duration := 0.0
var remaining := 0.0
var stacking := &"refresh"
var magnitude := 0.0
var tick_interval := 0.0
var tick_elapsed := 0.0

func setup(value_id: StringName, value_source: StringName, value_duration := 0.0, value_debuff := false) -> void:
	effect_id = value_id; source_id = value_source; duration = value_duration; remaining = duration; is_debuff = value_debuff

func tick(delta: float) -> bool:
	if duration <= 0.0: return true
	remaining = maxf(remaining - delta, 0.0)
	return remaining > 0.0

func refresh() -> void:
	remaining = duration

class EffectHost:
	var effects: Array[EffectRuntime] = []
	func add_effect(effect: EffectRuntime, target: EnemyRuntime) -> bool:
		if target.is_magic_immune and effect.effect_school == &"Magical": return false
		for current in effects:
			if current.effect_id == effect.effect_id and current.source_id == effect.source_id:
				if current.stacking == &"stack": effects.append(effect)
				else: current.refresh()
				return true
		effects.append(effect); return true
	func cleanse() -> void:
		effects = effects.filter(func(effect: EffectRuntime): return not effect.is_debuff)
	func tick(delta: float) -> void:
		for effect in effects.duplicate():
			if not effect.tick(delta): effects.erase(effect)
