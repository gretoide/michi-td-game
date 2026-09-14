class_name TargetController
extends RefCounted

signal target_changed(target: EnemyRuntime)
enum Mode { AUTO, MANUAL, STOPPED }
var mode := Mode.AUTO
var target: EnemyRuntime
var entered_order: Array[EnemyRuntime] = []

func observe(enemy: EnemyRuntime, tower_position: Vector2, range_units: float) -> void:
	if enemy == null or not enemy.is_alive() or enemy in entered_order: return
	if tower_position.distance_to(enemy.position) <= range_units: entered_order.append(enemy)

func acquire(tower_position: Vector2, range_units: float, enemies: Array[EnemyRuntime]) -> EnemyRuntime:
	if mode == Mode.STOPPED: return null
	if mode == Mode.MANUAL and _valid(target, tower_position, range_units): return target
	for enemy in enemies:
		observe(enemy, tower_position, range_units)
	for enemy in entered_order:
		if _valid(enemy, tower_position, range_units):
			_set_target(enemy); return enemy
	entered_order = entered_order.filter(func(value: EnemyRuntime): return value != null and value.is_alive())
	_set_target(null); return null

func set_manual(candidate: EnemyRuntime, tower_position: Vector2, range_units: float) -> bool:
	if _valid(candidate, tower_position, range_units): mode = Mode.MANUAL; _set_target(candidate); return true
	mode = Mode.AUTO; _set_target(null); return false

func toggle_stop() -> void:
	mode = Mode.AUTO if mode == Mode.STOPPED else Mode.STOPPED
	if mode == Mode.STOPPED: _set_target(null)

func tick(tower_position: Vector2, range_units: float, enemies: Array[EnemyRuntime]) -> EnemyRuntime:
	if target != null and not target.is_alive(): target = null
	if mode == Mode.MANUAL and not _valid(target, tower_position, range_units): mode = Mode.AUTO; target = null
	return acquire(tower_position, range_units, enemies)

func _valid(candidate: EnemyRuntime, origin: Vector2, radius: float) -> bool:
	return candidate != null and candidate.is_alive() and origin.distance_to(candidate.position) <= radius

func _set_target(value: EnemyRuntime) -> void:
	if target == value: return
	target = value; target_changed.emit(target)
