class_name EnemyRuntime
extends RefCounted

signal damaged(amount: float, result)
signal died
signal escaped
signal reached_path_end
signal checkpoint_reached(index: int)
var id: int
var profile_id: StringName
var movement_type := "Ground"
var position := Vector2.ZERO
var max_hp := 1.0
var hp := 1.0
var attack := 1
var xp_reward := 0
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
var checkpoint_cells: Array[Vector2i] = []
var reached_checkpoint_indices := {}
var next_checkpoint_index := 0
var rush_remaining := 0.0
var recharge_accumulator := 0.0
var evasion_chance := 0.0
var invisible := false
var disarm_aura_radius := 0.0

func setup(value_id: int, profile: EnemyProfileDefinition, start_position := Vector2.ZERO) -> void:
	id = value_id; profile_id = profile.id; movement_type = profile.movement_type; position = start_position
	max_hp = maxf(profile.hp, 1.0); hp = max_hp; armor = profile.armor; magic_resistance = profile.magic_resistance; attack = profile.attack; xp_reward = profile.xp_reward
	movement_speed = maxf(profile.base_speed, 20.0)
	for ability in profile.ability_ids: abilities[StringName(ability)] = true
	is_magic_immune = abilities.has(&"magic_immunity")
	is_physical_immune = abilities.has(&"physical_immune")
	if abilities.has(&"high_armor"): armor += 20.0
	invisible = abilities.has(&"invisible")
	if abilities.has(&"evasion"): evasion_chance = 0.5
	if abilities.has(&"disarm_aura"): disarm_aura_radius = 300.0

func is_alive() -> bool:
	return alive and hp > 0.0

func apply_damage(result) -> float:
	if not is_alive(): return 0.0
	var applied := minf(maxf(result.final_damage, 0.0), hp)
	hp -= applied; damage_accumulator += applied; damaged.emit(applied, result)
	if hp <= 0.0:
		alive = false; died.emit()
	return applied

func tick_abilities(delta: float) -> void:
	if not is_alive(): return
	if rush_remaining > 0.0: rush_remaining = maxf(0.0, rush_remaining - delta)
	if abilities.has(&"recharge"):
		recharge_accumulator += delta
		while recharge_accumulator >= 1.0:
			recharge_accumulator -= 1.0; hp = minf(max_hp, hp + max_hp * 0.01)

func trigger_rush() -> void:
	if abilities.has(&"rush"): rush_remaining = 3.0

func effective_move_speed() -> float:
	var multiplier := 1.5 if rush_remaining > 0.0 else 1.0
	return maxf(20.0, movement_speed * multiplier)

func mark_escaped() -> void:
	if not is_alive(): return
	alive = false; escaped.emit()

func set_path(cells: Array[Vector2i]) -> void:
	path.clear()
	for cell in cells: path.append(Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
	path_index = 0
	next_checkpoint_index = 0
	if not path.is_empty(): position = path[0]

func set_waypoint_path(cells: Array[Vector2i]) -> void:
	# Flying enemies use the ordered spawn/checkpoint/endpoint points and do
	# not need every ground route cell. Their movement remains continuous, but
	# ignores construction occupancy and follows the waypoint sequence.
	if movement_type.to_lower() != "flying" or cells.is_empty(): return
	path.clear()
	for cell in cells: path.append(Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
	path_index = 0
	next_checkpoint_index = 0
	if not path.is_empty(): position = path[0]

func refresh_waypoint_path(cells: Array[Vector2i]) -> void:
	if movement_type.to_lower() != "flying" or cells.is_empty(): return
	var rebuilt: Array[Vector2] = []
	for cell in cells: rebuilt.append(Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
	# A live enemy may only continue from its current progress.  Searching the
	# whole route can select an earlier waypoint after a construction update and
	# make the enemy visibly walk backwards.
	var closest := mini(path_index, rebuilt.size() - 1)
	var closest_distance := INF
	for index in range(closest, rebuilt.size()):
		var distance := position.distance_squared_to(rebuilt[index])
		if distance < closest_distance:
			closest_distance = distance
			closest = index
	path = rebuilt
	path_index = closest

func refresh_path(cells: Array[Vector2i]) -> void:
	if movement_type.to_lower() == "flying": return
	var rebuilt: Array[Vector2] = []
	for cell in cells: rebuilt.append(Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
	if rebuilt.is_empty(): return
	var closest := mini(path_index, rebuilt.size() - 1)
	var closest_distance := INF
	for index in range(closest, rebuilt.size()):
		var distance := position.distance_squared_to(rebuilt[index])
		if distance < closest_distance:
			closest_distance = distance
			closest = index
	path = rebuilt
	path_index = closest

func move_along_path(delta: float) -> void:
	if not is_alive() or path_index >= path.size() - 1: return
	position = position.move_toward(path[path_index + 1], effective_move_speed() * delta)
	if position.is_equal_approx(path[path_index + 1]):
		path_index += 1
		if path_index < path.size() - 1:
			var reached_cell := Vector2i(floori(path[path_index].x / 100.0), floori(path[path_index].y / 100.0))
			var checkpoint_index := checkpoint_cells.find(reached_cell)
			# Checkpoint events are ordered by the route, never by whichever
			# checkpoint happens to be crossed first during a detour.
			if checkpoint_index == next_checkpoint_index and not reached_checkpoint_indices.has(checkpoint_index):
				reached_checkpoint_indices[checkpoint_index] = true
				next_checkpoint_index += 1
				checkpoint_reached.emit(checkpoint_index)
		else: reached_path_end.emit()

func set_checkpoint_cells(value: Array[Vector2i]) -> void:
	checkpoint_cells = value.duplicate(); reached_checkpoint_indices.clear(); next_checkpoint_index = 0
