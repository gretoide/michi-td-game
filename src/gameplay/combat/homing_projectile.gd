class_name HomingProjectile
extends RefCounted

signal impacted(result)
signal invalidated
var origin := Vector2.ZERO
var position := Vector2.ZERO
var speed := 1000.0
var target: EnemyRuntime
var payload: DamagePipeline.DamageContext
var active := true
var source_gem_id := StringName()
var direction := Vector2.RIGHT

func setup(value_origin: Vector2, value_target: EnemyRuntime, value_payload: DamagePipeline.DamageContext, value_speed := 1000.0, value_source_gem_id := StringName()) -> void:
	origin = value_origin; position = origin; target = value_target; payload = value_payload; speed = value_speed; source_gem_id = value_source_gem_id
	if target != null and not position.is_equal_approx(target.position):
		direction = position.direction_to(target.position)

func tick(delta: float, pipeline := DamagePipeline) -> bool:
	if not active: return false
	if target == null or not target.is_alive():
		active = false; invalidated.emit(); return false
	var distance := position.distance_to(target.position)
	var step := speed * delta
	if distance > 0.0: direction = position.direction_to(target.position)
	if distance <= step:
		position = target.position
		var result := pipeline.resolve(payload, target)
		target.apply_damage(result); active = false; impacted.emit(result); return false
	position = position.move_toward(target.position, step)
	return true
