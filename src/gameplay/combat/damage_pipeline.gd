class_name DamagePipeline
extends RefCounted

enum DamageType { PHYSICAL, MAGIC, PURE }
class DamageContext:
	var base_damage := 0.0
	var damage_type := DamageType.PHYSICAL
	var multiplier := 1.0
	var critical_multiplier := 1.0
	var pierce := 0.0
	var random_source: RandomSource

class DamageResult:
	var final_damage := 0.0
	var mitigated_damage := 0.0
	var damage_type := DamageType.PHYSICAL

static func resolve(context: DamageContext, target: EnemyRuntime) -> DamageResult:
	var result := DamageResult.new(); result.damage_type = context.damage_type
	var value := maxf(context.base_damage, 0.0) * maxf(context.multiplier, 0.0) * maxf(context.critical_multiplier, 0.0)
	if target.evasion_chance > 0.0 and context.random_source != null and context.random_source.next_float() < target.evasion_chance:
		result.final_damage = 0.0; result.mitigated_damage = 0.0; return result
	if context.damage_type == DamageType.PHYSICAL:
		if target.is_physical_immune: value = 0.0
		else:
			var armor := target.armor - context.pierce
			value *= _armor_multiplier(armor)
	elif context.damage_type == DamageType.MAGIC:
		if target.is_magic_immune: value = 0.0
		else: value *= clampf(1.0 - target.magic_resistance / 100.0, 0.0, 1.0)
	result.final_damage = maxf(value, 0.0); result.mitigated_damage = result.final_damage
	return result

static func _armor_multiplier(armor: float) -> float:
	return 1.0 if armor <= 0.0 else 100.0 / (100.0 + 0.06 * armor)
