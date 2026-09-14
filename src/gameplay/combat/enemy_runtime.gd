class_name EnemyRuntime
extends RefCounted

signal damaged(amount: float, result)
signal died
signal escaped
signal reached_path_end
var id: int
var profile_id: StringName
var position := Vector2.ZERO
var max_hp := 1.0
var hp := 1.0
var armor := 0.0
var magic_resistance := 0.0
var abilities: Dictionary = {}
var alive := true
var is_magic_immune := false
var is_physical_immune := false
var damage_accumulator := 0.0
var movement_speed := 250.0
var path: Array[Vector2] = []
var path_index := 0

func setup(value_id: int, profile: EnemyProfileDefinition, start_position := Vector2.ZERO) -> void:
	id = value_id; profile_id = profile.id; position = start_position
	max_hp = maxf(profile.hp, 1.0); hp = max_hp; armor = profile.armor; magic_resistance = profile.magic_resistance
	movement_speed = maxf(profile.base_speed, 20.0)
	for ability in profile.ability_ids: abilities[StringName(ability)] = true
	is_magic_immune = abilities.has(&"magic_immunity")
	is_physical_immune = abilities.has(&"physical_immune")

func is_alive() -> bool:
	return alive and hp > 0.0

func apply_damage(result) -> float:
	if not is_alive(): return 0.0
	var applied := minf(maxf(result.final_damage, 0.0), hp)
	hp -= applied; damage_accumulator += applied; damaged.emit(applied, result)
	if hp <= 0.0:
		alive = false; died.emit()
	return applied

func mark_escaped() -> void:
	if not is_alive(): return
	alive = false; escaped.emit()

func set_path(cells: Array[Vector2i]) -> void:
	path.clear()
	for cell in cells: path.append(Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
	path_index = 0
	if not path.is_empty(): position = path[0]

func move_along_path(delta: float) -> void:
	if not is_alive() or path_index >= path.size() - 1: return
	position = position.move_toward(path[path_index + 1], movement_speed * delta)
	if position.is_equal_approx(path[path_index + 1]):
		path_index += 1
		if path_index >= path.size() - 1: reached_path_end.emit()
