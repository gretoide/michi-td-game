class_name TowerRuntime
extends RefCounted

signal attack_started(target: EnemyRuntime, projectile: HomingProjectile)
signal state_changed
var id: StringName
var position := Vector2.ZERO
var gem: GemInstance
var stats := TowerCombatStats.new()
var targeting := TargetController.new()
var cooldown := 0.0
var stopped := false
var disarmed := false

func setup(value_gem: GemInstance, definition: GemDefinition, world_position := Vector2.ZERO) -> void:
	gem = value_gem; id = gem.id; position = world_position; stats = TowerCombatStats.from_gem(gem, definition)

func toggle_stop() -> void:
	targeting.toggle_stop(); stopped = targeting.mode == TargetController.Mode.STOPPED; state_changed.emit()

func attack(target: EnemyRuntime) -> bool:
	if target == null or not target.is_alive(): return false
	return targeting.set_manual(target, position, stats.range_units)

func tick(delta: float, enemies: Array[EnemyRuntime], projectile_speed := 1000.0) -> HomingProjectile:
	if cooldown > 0.0: cooldown = maxf(cooldown - delta, 0.0)
	var target := targeting.tick(position, stats.range_units, enemies)
	if disarmed or target == null or cooldown > 0.0 or targeting.mode == TargetController.Mode.STOPPED: return null
	var payload := DamagePipeline.DamageContext.new(); payload.base_damage = stats.damage; payload.damage_type = DamagePipeline.DamageType.PHYSICAL
	var projectile := HomingProjectile.new(); projectile.setup(position, target, payload, projectile_speed); cooldown = stats.attack_interval(); attack_started.emit(target, projectile); return projectile
