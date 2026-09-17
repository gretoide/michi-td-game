class_name WaveRuntime
extends RefCounted

signal enemy_spawned(id: int, profile: EnemyProfileDefinition)
signal enemy_resolved(id: int, resolution: StringName)
signal wave_completed

var pending := 0
var alive := 0
var resolved := 0
var _definition: WaveDefinition
var _profile: EnemyProfileDefinition
var _elapsed := 0.0
var _next_id := 1
var _active := false
var _active_ids: Dictionary = {}

func start(definition: WaveDefinition, profile: EnemyProfileDefinition) -> void:
	_definition = definition; _profile = profile
	pending = definition.spawn_count; alive = 0; resolved = 0
	_elapsed = definition.spawn_interval; _next_id = 1; _active = true
	_active_ids.clear()

func tick(delta: float) -> void:
	if not _active or pending <= 0: return
	_elapsed += delta
	while pending > 0 and _elapsed >= _definition.spawn_interval:
		_elapsed -= _definition.spawn_interval
		var id := _next_id; _next_id += 1; pending -= 1; alive += 1; _active_ids[id] = true
		enemy_spawned.emit(id, _profile)

func resolve_enemy(id: int, resolution: StringName) -> bool:
	if not _active or not _active_ids.has(id) or resolution not in [&"death", &"escaped"]: return false
	_active_ids.erase(id); alive -= 1; resolved += 1; enemy_resolved.emit(id, resolution)
	_check_completed(); return true

func _check_completed() -> void:
	if _active and pending == 0 and alive == 0:
		_active = false; wave_completed.emit()

func is_active() -> bool:
	return _active

func total_count() -> int:
	# The HUD needs the authoritative count for the active wave.  Derive it
	# from the runtime counters so it stays aligned with what WaveRuntime will
	# actually instantiate, including enemies already resolved during combat.
	return pending + alive + resolved if _definition != null else 0
