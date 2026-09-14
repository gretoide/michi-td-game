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

func setup(value_origin: Vector2, value_target: EnemyRuntime, value_payload: DamagePipeline.DamageContext, value_speed := 1000.0) -> void:
	origin = value_origin; position = origin; target = value_target; payload = value_payload; speed = value_speed

func tick(delta: float, pipeline := DamagePipeline) -> bool:
	if not active: return false
	if target == null or not target.is_alive():
		active = false; invalidated.emit(); return false
	var distance := position.distance_to(target.position)
	var step := speed * delta
	if distance <= step:
		position = target.position
		var result := pipeline.resolve(payload, target)
		target.apply_damage(result); active = false; impacted.emit(result); return false
	position = position.move_toward(target.position, step)
	return true
