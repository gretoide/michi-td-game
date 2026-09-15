class_name TowerRuntime
extends RefCounted

signal attack_started(target: EnemyRuntime, projectile: HomingProjectile)
signal state_changed
var id: StringName
var position := Vector2.ZERO
var gem: GemInstance
var stats := TowerCombatStats.new()
var damage_type := DamagePipeline.DamageType.PHYSICAL
var targeting := TargetController.new()
var cooldown := 0.0
var stopped := false
var disarmed := false

func setup(value_gem: GemInstance, definition: GemDefinition, world_position := Vector2.ZERO) -> void:
	gem = value_gem; id = gem.id; position = world_position; stats = TowerCombatStats.from_gem(gem, definition); damage_type = _damage_type_for(definition)

func _damage_type_for(definition: GemDefinition) -> DamagePipeline.DamageType:
	if definition == null: return DamagePipeline.DamageType.PHYSICAL
	var level_data: Dictionary = {}
	for item in definition.levels:
		if int(item.get("level", 1)) == gem.level:
			level_data = item; break
	if level_data.is_empty() and not definition.levels.is_empty(): level_data = definition.levels[0]
	var ability := str(level_data.get("ability", "")).to_lower()
	var ability_ids: Variant = level_data.get("ability_ids", PackedStringArray())
	var magic_words := ["poison", "slow", "aura", "burn", "stun", "corrupt", "recover", "accuracy", "overlook"]
	for word in magic_words:
		if ability.contains(word): return DamagePipeline.DamageType.MAGIC
	for value in ability_ids:
		if str(value).to_lower() in magic_words: return DamagePipeline.DamageType.MAGIC
	return DamagePipeline.DamageType.PHYSICAL

func toggle_stop() -> void:
	targeting.toggle_stop(); stopped = targeting.mode == TargetController.Mode.STOPPED; state_changed.emit()

func attack(target: EnemyRuntime) -> bool:
	if target == null or not target.is_alive(): return false
	return targeting.set_manual(target, position, stats.range_units)

func tick(delta: float, enemies: Array[EnemyRuntime], projectile_speed := 1000.0) -> HomingProjectile:
	if cooldown > 0.0: cooldown = maxf(cooldown - delta, 0.0)
	var target := targeting.tick(position, stats.range_units, enemies)
	if disarmed or target == null or cooldown > 0.0 or targeting.mode == TargetController.Mode.STOPPED: return null
	var payload := DamagePipeline.DamageContext.new(); payload.base_damage = stats.damage; payload.damage_type = damage_type
	var projectile := HomingProjectile.new(); projectile.setup(position, target, payload, projectile_speed, gem.id); cooldown = stats.attack_interval(); attack_started.emit(target, projectile); return projectile
