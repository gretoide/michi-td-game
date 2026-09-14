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
var spawn_counter := 0

func setup(value_projectile_speed := 1000.0, value_path: Array[Vector2i] = []) -> void:
	projectile_speed = value_projectile_speed; path_cells = value_path

func add_tower(tower: TowerRuntime) -> void:
	if tower == null: return
	towers.append(tower)

func spawn_enemy(profile: EnemyProfileDefinition, cell := Vector2i.ZERO) -> EnemyRuntime:
	if profile == null: return null
	spawn_counter += 1
	var enemy := EnemyRuntime.new(); enemy.setup(spawn_counter, profile, Vector2(cell) * 100.0 + Vector2.ONE * 50.0)
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
		tower.disarmed = false
		for enemy in enemies:
			if enemy.is_alive() and enemy.disarm_aura_radius > 0.0 and tower.position.distance_to(enemy.position) <= enemy.disarm_aura_radius:
				tower.disarmed = true; break
		var projectile := tower.tick(delta, enemies, projectile_speed)
		if projectile != null: projectiles.append(projectile); projectile_created.emit(projectile)
	for projectile in projectiles.duplicate():
		if not projectile.tick(delta): projectiles.erase(projectile)
	enemies = enemies.filter(func(enemy: EnemyRuntime): return enemy != null and enemy.is_alive())
	combat_changed.emit()
