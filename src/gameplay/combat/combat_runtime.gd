class_name CombatRuntime
extends RefCounted

signal enemy_spawned(enemy: EnemyRuntime)
signal projectile_created(projectile: HomingProjectile)
signal damage_applied(enemy: EnemyRuntime, amount: float)
signal combat_changed
var towers: Array[TowerRuntime] = []
var enemies: Array[EnemyRuntime] = []
var projectiles: Array[HomingProjectile] = []
var projectile_speed := 1000.0
var effect_system: EffectSystem
var path_cells: Array[Vector2i] = []
var waypoint_cells: Array[Vector2i] = []
var spawn_counter := 0

func setup(value_projectile_speed := 1000.0, value_path: Array[Vector2i] = [], value_waypoints: Array[Vector2i] = []) -> void:
	projectile_speed = value_projectile_speed
	set_navigation_cache(value_path, value_waypoints)

func set_navigation_cache(value_path: Array[Vector2i], value_waypoints: Array[Vector2i] = []) -> void:
	# The cache is replaced atomically at a phase boundary. Enemies spawned
	# afterwards receive this exact snapshot instead of solving a partial path
	# while the wave is already running.
	path_cells = value_path.duplicate()
	waypoint_cells = value_waypoints.duplicate()

func refresh_enemy_paths(value_path: Array[Vector2i], value_waypoints: Array[Vector2i] = []) -> void:
	path_cells = value_path.duplicate()
	# Keep the existing direct waypoint snapshot when callers are only
	# refreshing Ground (the optional argument preserves the old API).
	if not value_waypoints.is_empty(): waypoint_cells = value_waypoints.duplicate()
	if path_cells.is_empty(): return
	for enemy: EnemyRuntime in enemies:
		if enemy == null or not enemy.is_alive(): continue
		if enemy.movement_type.to_lower() == "flying":
			if not waypoint_cells.is_empty(): enemy.refresh_waypoint_path(waypoint_cells)
		else:
			enemy.refresh_path(path_cells)

func clear_projectiles() -> void:
	if projectiles.is_empty(): return
	for projectile: HomingProjectile in projectiles:
		if projectile != null: projectile.active = false
	projectiles.clear()
	combat_changed.emit()

func add_tower(tower: TowerRuntime) -> void:
	if tower == null: return
	towers.append(tower)

func spawn_enemy(profile: EnemyProfileDefinition, cell := Vector2i.ZERO) -> EnemyRuntime:
	if profile == null: return null
	var is_flying := profile.movement_type.to_lower() == "flying"
	# A missing cache is a navigation error, not a reason to send an enemy in a
	# straight line. GameRuntime validates this before wave.start(); this guard
	# keeps debug/manual spawns from bypassing that invariant.
	if (is_flying and waypoint_cells.is_empty()) or (not is_flying and path_cells.is_empty()):
		return null
	spawn_counter += 1
	var enemy := EnemyRuntime.new(); enemy.setup(spawn_counter, profile, Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
	if is_flying:
		enemy.set_waypoint_path(waypoint_cells)
	else:
		enemy.set_path(path_cells)
	enemy.damaged.connect(func(amount: float, _result): damage_applied.emit(enemy, amount))
	if effect_system != null: enemy.damaged.connect(func(amount: float, _result): effect_system.on_damage(enemy, amount))
	enemy.reached_path_end.connect(func(): enemy.mark_escaped())
	enemies.append(enemy); enemy_spawned.emit(enemy); combat_changed.emit(); return enemy

func tick(delta: float) -> void:
	for enemy in enemies:
		enemy.tick_abilities(delta)
		enemy.move_along_path(delta)
	for tower in towers:
		if not tower.attack_enabled:
			tower.disarmed = false
			continue
		tower.disarmed = false
		for enemy in enemies:
			if enemy.is_alive() and enemy.disarm_aura_radius > 0.0 and tower.position.distance_to(enemy.position) <= enemy.disarm_aura_radius:
				tower.disarmed = true; break
		var projectile := tower.tick(delta, enemies, projectile_speed)
		if projectile != null:
			projectile.impacted.connect(func(_result): _execute_tower_abilities(projectile))
			projectiles.append(projectile); projectile_created.emit(projectile)
	for projectile in projectiles.duplicate():
		if not projectile.tick(delta): projectiles.erase(projectile)
	enemies = enemies.filter(func(enemy: EnemyRuntime): return enemy != null and enemy.is_alive())
	combat_changed.emit()

func _execute_tower_abilities(projectile: HomingProjectile) -> void:
	if effect_system == null or projectile == null or projectile.target == null: return
	var target := projectile.target
	for ability in projectile.ability_ids:
		var key := str(ability).to_lower()
		if key == "cleave": _apply_cleave(projectile)
		elif key == "split": _apply_split(projectile)
		elif key == "slow": effect_system.apply_slow(target, projectile.source_gem_id, 20.0, 1.5)
		elif key == "poison": effect_system.apply_poison(target, projectile.source_gem_id, maxf(target.max_hp * 0.01, 1.0), 1.0)
		elif key == "burn": effect_system.apply_burn(target, projectile.source_gem_id, maxf(target.max_hp * 0.01, 1.0), 1.0)
		elif key == "stone_gaze": effect_system.apply_stone_gaze(target, projectile.source_gem_id, 1.0)

func _apply_cleave(projectile: HomingProjectile) -> void:
	var target := projectile.target
	for enemy: EnemyRuntime in enemies:
		if enemy == target or not enemy.is_alive() or target.position.distance_to(enemy.position) > 150.0: continue
		var context := _ability_damage_context(projectile, 0.5)
		enemy.apply_damage(DamagePipeline.resolve(context, enemy))

func _apply_split(projectile: HomingProjectile) -> void:
	var candidates: Array[EnemyRuntime] = []
	for enemy: EnemyRuntime in enemies:
		if enemy != projectile.target and enemy != null and enemy.is_alive(): candidates.append(enemy)
	candidates.sort_custom(func(a: EnemyRuntime, b: EnemyRuntime): return projectile.target.position.distance_to(a.position) < projectile.target.position.distance_to(b.position))
	var hits := mini(projectile.ability_level, candidates.size())
	for index in hits:
		var context := _ability_damage_context(projectile, 1.0)
		candidates[index].apply_damage(DamagePipeline.resolve(context, candidates[index]))

func _ability_damage_context(projectile: HomingProjectile, multiplier: float) -> DamagePipeline.DamageContext:
	var context := DamagePipeline.DamageContext.new()
	context.base_damage = projectile.payload.base_damage
	context.damage_type = projectile.payload.damage_type
	context.multiplier = multiplier
	return context
