class_name GameRuntime
extends RefCounted

const MAP_PATH := "res://data/gameplay/initial_map.tres"
const ProgressRuntimeScript = preload("res://src/gameplay/progression/progress_runtime.gd")
const EconomyRuntimeScript = preload("res://src/gameplay/progression/economy_runtime.gd")
const PlayerProgressionRuntimeScript = preload("res://src/gameplay/progression/player_progression_runtime.gd")
const GameOutcomeRuntimeScript = preload("res://src/gameplay/progression/game_outcome_runtime.gd")
const SupportSkillCatalogScript = preload("res://src/gameplay/progression/support_skill_catalog.gd")
const SupportRewardRuntimeScript = preload("res://src/gameplay/progression/support_reward_runtime.gd")

var foundation: GameplayFoundation
var grid: GridModel
var map: MapLayout
var pathfinder: GroundPathfinder
var phases: GamePhaseMachine
var wave: WaveRuntime
var gem_generator: GemGenerator
var construction: ConstructionRuntime
var mvp: MvpState
var combat: CombatRuntime
var effects: EffectSystem
var progress: RefCounted
var economy: RefCounted
var progression: RefCounted
var outcome: RefCounted
var support_skills: RefCounted
var support_rewards: RefCounted
var wave_definitions: Array[WaveDefinition] = []
var cached_ground_route: Array[Vector2i] = []
var cached_waypoint_route: Array[Vector2i] = []
var navigation_ready := false
var current_wave_is_boss := false
var player_state: Dictionary
var outcome_state := "playing"

func initialize(seed: int = -1) -> PackedStringArray:
	grid = GridModel.new()
	map = load(MAP_PATH) as MapLayout
	if map == null: return PackedStringArray(["Initial map could not be loaded"])
	var map_errors := map.validate_for(grid)
	if not map_errors.is_empty(): return map_errors
	for waypoint: Vector2i in map.ordered_waypoints(): grid.reserve(waypoint)
	_block_outer_border()
	_block_restricted_zones()
	foundation = GameplayFoundation.new()
	var loaded := foundation.initialize(seed)
	if not loaded.is_valid():
		var messages := PackedStringArray()
		for error in loaded.errors: messages.append(str(error))
		return messages
	pathfinder = GroundPathfinder.new(grid)
	var initial_route := _calculate_navigation_snapshot()
	if initial_route.is_empty(): return PackedStringArray(["Initial Ground route is invalid"])
	phases = GamePhaseMachine.new(); phases.reset()
	phases.phase_exited.connect(_on_phase_exited)
	wave = WaveRuntime.new()
	gem_generator = GemGenerator.new(foundation.random)
	mvp = MvpState.new()
	construction = ConstructionRuntime.new()
	construction.setup(grid, pathfinder, phases, gem_generator, foundation.catalog.recipes, map)
	construction.begin_round(1)
	combat = CombatRuntime.new()
	effects = EffectSystem.new()
	combat.effect_system = effects
	# Cache both navigation variants after the map and construction grid are
	# ready: ground enemies use every route cell, flying enemies use only the
	# ordered spawn/checkpoint/endpoint waypoints.
	combat.setup(foundation.catalog.globals.projectile_speed, cached_ground_route, cached_waypoint_route)
	progress = ProgressRuntimeScript.new(); progress.reset()
	economy = EconomyRuntimeScript.new(); economy.reset()
	progression = PlayerProgressionRuntimeScript.new(); progression.reset()
	outcome = GameOutcomeRuntimeScript.new(); outcome.reset()
	outcome_state = "playing"
	support_skills = SupportSkillCatalogScript.new()
	support_rewards = SupportRewardRuntimeScript.new(); support_rewards.setup(support_skills, foundation.random); support_rewards.reset()
	support_rewards.reward_chosen.connect(func(_skill_id: StringName, _level: int): _advance_after_reward())
	wave_definitions = _build_wave_definitions()
	wave.enemy_spawned.connect(_on_wave_enemy_spawned)
	construction.construction_finalized.connect(_on_construction_finalized)
	construction.navigation_changed.connect(_on_navigation_changed)
	player_state = {"wave": 1, "lives": 1000, "max_lives": 1000, "score": 0, "gold": 0, "xp": 0, "player_level": 1, "progress": 50.0, "base_enemy_count": 10, "support_skills": {}}
	progress.changed.connect(func(value: float): player_state.progress = value)
	economy.changed.connect(func(value: int): player_state.gold = value)
	progression.changed.connect(func(value: int, quality: int): player_state.xp = value; player_state.player_level = quality)
	outcome.life_changed.connect(func(value: int): player_state.lives = value)
	outcome.defeated.connect(func(): outcome_state = "defeat")
	outcome.victorious.connect(func(): outcome_state = "victory")
	return PackedStringArray()

func _block_outer_border() -> void:
	for x in range(GridModel.WIDTH):
		grid.block(Vector2i(x, 0))
		grid.block(Vector2i(x, GridModel.HEIGHT - 1))
	for y in range(1, GridModel.HEIGHT - 1):
		grid.block(Vector2i(0, y))
		grid.block(Vector2i(GridModel.WIDTH - 1, y))

func _block_restricted_zones() -> void:
	# Fixed V1 spawn/end areas. Coordinates in the design document are
	# one-based; GridModel is zero-based, so the lower block's (29,28)-(36,36)
	# design rectangle becomes x=28..35, y=27..35 here. They are tracked
	# separately from walkability so the route can still traverse their special
	# spawn and endpoint cells.
	const SPAWN_RESTRICTED_MIN := Vector2i(1, 1)
	const SPAWN_RESTRICTED_MAX := Vector2i(10, 7)
	const END_RESTRICTED_MIN := Vector2i(28, 27)
	const END_RESTRICTED_MAX := Vector2i(GridModel.WIDTH - 1, GridModel.HEIGHT - 1)
	for y in range(SPAWN_RESTRICTED_MIN.y, SPAWN_RESTRICTED_MAX.y + 1):
		for x in range(SPAWN_RESTRICTED_MIN.x, SPAWN_RESTRICTED_MAX.x + 1):
			grid.restrict(Vector2i(x, y))
	for y in range(END_RESTRICTED_MIN.y, END_RESTRICTED_MAX.y + 1):
		for x in range(END_RESTRICTED_MIN.x, END_RESTRICTED_MAX.x + 1):
			grid.restrict(Vector2i(x, y))

func start_first_wave() -> bool:
	if wave == null or wave.is_active(): return false
	# Resolve the complete route before changing phase or starting the wave.
	# This is the gameplay snapshot every enemy in this wave will receive.
	var prepared_route := pathfinder.find_route(map) if pathfinder != null and map != null else []
	if prepared_route.is_empty():
		navigation_ready = false
		cached_ground_route.clear()
		return false
	if phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
		phases.resolve_construction()
	if phases.phase != GamePhaseMachine.Phase.COMBAT: return false
	_set_navigation_snapshot(prepared_route)
	combat.set_navigation_cache(cached_ground_route, cached_waypoint_route)
	var definition := wave_definitions[phases.wave_number - 1] as WaveDefinition
	var profile := foundation.catalog.enemy_profile_by_id(definition.enemy_profile_id) as EnemyProfileDefinition
	if profile == null: return false
	current_wave_is_boss = definition.boss
	definition.spawn_count = enemy_count_for_wave(phases.wave_number)
	player_state.base_enemy_count = definition.spawn_count
	wave.start(definition, profile)
	wave.wave_completed.connect(_on_wave_completed, CONNECT_ONE_SHOT)
	return true

func tick(delta: float) -> void:
	if phases != null and phases.phase == GamePhaseMachine.Phase.COMBAT and outcome_state == "playing":
		wave.tick(delta)
		combat.tick(delta)
		effects.tick(delta)

func enemy_count_for_display() -> int:
	"""Return the count already resolved by the wave domain for the HUD.

	During combat this is the active WaveRuntime total. During Construction it
	uses the next catalog wave and the current future-count modifier, including
	boss waves, without duplicating the Progress formula in the UI layer.
	"""
	if wave != null and wave.is_active():
		return wave.total_count()
	if phases == null: return 0
	return enemy_count_for_wave(phases.wave_number)

func enemy_count_for_wave(wave_number: int) -> int:
	"""Single authoritative count for preview and the spawned WaveRuntime."""
	if wave_definitions.is_empty(): return 0
	var index := clampi(wave_number - 1, 0, wave_definitions.size() - 1)
	var definition := wave_definitions[index] as WaveDefinition
	if definition == null: return 0
	return 1 if definition.boss else maxi(1, 10 + (progress.future_count_modifier if progress != null else 0))

func _on_wave_enemy_spawned(wave_enemy_id: int, profile: EnemyProfileDefinition) -> void:
	var enemy := combat.spawn_enemy(profile, map.spawn)
	if enemy == null:
		# This should be unreachable because start_first_wave validates the
		# snapshot first. Resolve the reservation defensively so a bad debug
		# spawn cannot leave WaveRuntime stuck forever.
		wave.resolve_enemy(wave_enemy_id, &"escaped")
		return
	var tier := floori((phases.wave_number - 1) / 10.0)
	enemy.xp_reward = (3000 if current_wave_is_boss else 48) * int(pow(2, tier))
	enemy.set_checkpoint_cells(map.checkpoints)
	enemy.died.connect(func(): _on_enemy_resolved(enemy, wave_enemy_id, &"death"))
	enemy.escaped.connect(func(): _on_enemy_resolved(enemy, wave_enemy_id, &"escaped"))
	enemy.checkpoint_reached.connect(func(index: int): progress.on_checkpoint(index, current_wave_is_boss))

func _on_enemy_resolved(enemy: EnemyRuntime, wave_enemy_id: int, resolution: StringName) -> void:
	if not wave.resolve_enemy(wave_enemy_id, resolution): return
	if resolution == &"death":
		var reward := 150 if current_wave_is_boss else 5
		economy.reward(enemy.id, reward, resolution); progression.add_xp(enemy.xp_reward); progress.on_kill(current_wave_is_boss, current_wave_is_boss and phases.wave_number == 50); outcome.register_kill(); player_state.score += 1
	else:
		economy.reward(enemy.id, 0, resolution); progress.on_final_checkpoint(current_wave_is_boss); outcome.register_escape(enemy.attack)

func _sync_combat_towers() -> void:
	if combat == null: return
	combat.towers.clear()
	for gem: GemInstance in construction.board_gems:
		var definition := foundation.catalog.gem_definition_for_id(gem.id) as GemDefinition
		var tower := TowerRuntime.new(); tower.setup(gem, definition, Vector2(gem.cell) * 100.0 + Vector2.ONE * 50.0); combat.add_tower(tower)

func _on_navigation_changed() -> void:
	if pathfinder == null or map == null: return
	var refreshed := pathfinder.find_route(map)
	if refreshed.is_empty():
		navigation_ready = false
		cached_ground_route.clear()
		if combat != null: combat.set_navigation_cache([], map.ordered_waypoints())
		return
	_set_navigation_snapshot(refreshed)
	# Placement happens only in Construction; do not repath active enemies from
	# that preview. Combat gets one authoritative refresh at its boundary.
	if combat != null and phases != null and phases.phase == GamePhaseMachine.Phase.COMBAT:
		combat.refresh_enemy_paths(cached_ground_route, cached_waypoint_route)

func _calculate_navigation_snapshot() -> Array[Vector2i]:
	if pathfinder == null or map == null: return []
	var route := pathfinder.find_route(map)
	if route.is_empty():
		navigation_ready = false
		cached_ground_route.clear()
		cached_waypoint_route.clear()
		return []
	_set_navigation_snapshot(route)
	return cached_ground_route.duplicate()

func _set_navigation_snapshot(route: Array[Vector2i]) -> void:
	cached_ground_route = route.duplicate()
	cached_waypoint_route = map.ordered_waypoints().duplicate() if map != null else []
	navigation_ready = not cached_ground_route.is_empty() and not cached_waypoint_route.is_empty()

func _on_phase_exited(previous_phase: GamePhaseMachine.Phase) -> void:
	if previous_phase == GamePhaseMachine.Phase.COMBAT and combat != null:
		combat.clear_projectiles()

func _on_construction_finalized(_result: GemInstance) -> void:
	_sync_combat_towers()
	start_first_wave()

func _on_wave_completed() -> void:
	if phases.wave_number >= 50:
		outcome.register_victory(); return
	if not support_rewards.generate_for_wave(phases.wave_number).is_empty(): return
	_advance_after_reward()

func _advance_after_reward() -> void:
	if phases.phase != GamePhaseMachine.Phase.COMBAT: return
	phases.resolve_combat(); player_state.wave = phases.wave_number; construction.begin_round(phases.wave_number)

func _build_wave_definitions() -> Array[WaveDefinition]:
	var result: Array[WaveDefinition] = []
	if foundation != null and foundation.catalog != null and foundation.catalog.waves.size() == 50:
		for item in foundation.catalog.waves:
			result.append(item as WaveDefinition)
		return result
	for number in range(1, 51):
		var definition := WaveDefinition.new(); definition.number = number; definition.enemy_profile_id = &"frenzied_pig"; definition.boss = number in [10, 20, 30, 40, 50]; definition.spawn_count = 1 if definition.boss else 10; definition.spawn_interval = 1.0; result.append(definition)
	return result
