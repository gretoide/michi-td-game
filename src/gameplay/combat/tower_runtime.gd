class_name TowerRuntime
extends RefCounted

signal attack_started(target: EnemyRuntime, projectile: HomingProjectile)
signal state_changed
var id: StringName
var position := Vector2.ZERO
var gem: GemInstance
var stats := TowerCombatStats.new()
var abilities: PackedStringArray = []
var damage_type := DamagePipeline.DamageType.PHYSICAL
var targeting := TargetController.new()
var cooldown := 0.0
var stopped := false
var disarmed := false
var attack_enabled := true

func setup(value_gem: GemInstance, definition: GemDefinition, world_position := Vector2.ZERO) -> void:
	gem = value_gem; id = gem.id; position = world_position; stats = TowerCombatStats.from_gem(gem, definition); abilities = _abilities_for(definition); damage_type = _damage_type_for(definition); attack_enabled = gem.attack_enabled

func toggle_attack_enabled() -> void:
	set_attack_enabled(not attack_enabled)

func set_attack_enabled(value: bool) -> void:
	attack_enabled = value
	if gem != null: gem.attack_enabled = value
	state_changed.emit()

func _abilities_for(definition: GemDefinition) -> PackedStringArray:
	var result := PackedStringArray()
	var level_data := TowerCombatStats.level_data_for(gem, definition)
	for value in level_data.get("ability_ids", PackedStringArray()):
		var key := str(value).to_lower()
		if not key.is_empty() and key != "sin_efecto" and key != "spell_steal_placeholder_v1" and key not in result: result.append(key)
	var display_ability := str(level_data.get("ability", "")).to_lower().strip_edges()
	if not display_ability.is_empty():
		var key := display_ability.split(" ")[0]
		if key not in result: result.append(key)
	return result

func _damage_type_for(definition: GemDefinition) -> DamagePipeline.DamageType:
	if definition == null: return DamagePipeline.DamageType.PHYSICAL
	var level_data := TowerCombatStats.level_data_for(gem, definition)
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
	var projectile := HomingProjectile.new(); projectile.setup(position, target, payload, projectile_speed, gem.id, abilities, gem.level); cooldown = stats.attack_interval(); attack_started.emit(target, projectile); return projectile
