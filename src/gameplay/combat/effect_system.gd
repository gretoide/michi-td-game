class_name EffectSystem
extends RefCounted

const MIN_MOVE_SPEED := 20.0
var hosts: Dictionary = {}
var targets: Dictionary = {}
var cleanse_accumulators: Dictionary = {}

func host_for(enemy: EnemyRuntime) -> EffectRuntime.EffectHost:
	if not hosts.has(enemy.id): hosts[enemy.id] = EffectRuntime.EffectHost.new()
	targets[enemy.id] = enemy
	return hosts[enemy.id]

func apply_slow(enemy: EnemyRuntime, source: StringName, amount: float, duration: float) -> bool:
	var effect := EffectRuntime.new(); effect.setup(&"slow", source, duration, true); effect.effect_school = &"Magical"; effect.magnitude = amount
	return host_for(enemy).add_effect(effect, enemy)

func apply_stone_gaze(enemy: EnemyRuntime, source: StringName, duration: float) -> bool:
	var effect := EffectRuntime.new(); effect.setup(&"stone_gaze", source, duration, true); effect.effect_school = &"NonMagical"
	return host_for(enemy).add_effect(effect, enemy)

func apply_burn(enemy: EnemyRuntime, source: StringName, damage_per_tick: float, duration: float) -> void:
	var effect := EffectRuntime.new(); effect.setup(&"burn", source, duration, true); effect.stacking = &"stack"; effect.effect_school = &"Magical"; effect.magnitude = damage_per_tick; effect.tick_interval = 0.25; host_for(enemy).add_effect(effect, enemy)

func apply_poison(enemy: EnemyRuntime, source: StringName, damage_per_tick: float, duration: float) -> void:
	var effect := EffectRuntime.new(); effect.setup(&"poison", source, duration, true); effect.stacking = &"stack"; effect.effect_school = &"Magical"; effect.magnitude = damage_per_tick; effect.tick_interval = 0.25; host_for(enemy).add_effect(effect, enemy)

func cleanse(enemy: EnemyRuntime) -> void:
	host_for(enemy).cleanse()
	cleanse_accumulators[enemy.id] = 0.0

func on_damage(enemy: EnemyRuntime, applied_damage: float) -> void:
	if enemy == null or not enemy.abilities.has(&"cleanse"): return
	var accumulator := float(cleanse_accumulators.get(enemy.id, 0.0)) + maxf(applied_damage, 0.0)
	var threshold := enemy.max_hp * 0.25
	while enemy.is_alive() and accumulator >= threshold:
		accumulator -= threshold; cleanse(enemy)
	cleanse_accumulators[enemy.id] = accumulator

func tick(delta: float) -> void:
	for enemy_id in hosts:
		var enemy: EnemyRuntime = targets.get(enemy_id)
		if enemy == null: continue
		var host: EffectRuntime.EffectHost = hosts[enemy_id]
		for effect in host.effects:
			if effect.tick_interval <= 0.0 or not enemy.is_alive(): continue
			effect.tick_elapsed += delta
			while effect.tick_elapsed >= effect.tick_interval and enemy.is_alive():
				effect.tick_elapsed -= effect.tick_interval
				var context := DamagePipeline.DamageContext.new(); context.base_damage = effect.magnitude; context.damage_type = effect.damage_type
				enemy.apply_damage(DamagePipeline.resolve(context, enemy))
		host.tick(delta)

func effective_move_speed(base_speed: float, slow_amounts: Array[float]) -> float:
	var total := base_speed
	for amount in slow_amounts: total -= amount
	return maxf(total, MIN_MOVE_SPEED)
