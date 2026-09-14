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
	foundation = GameplayFoundation.new()
	var loaded := foundation.initialize(seed)
	if not loaded.is_valid():
		var messages := PackedStringArray()
		for error in loaded.errors: messages.append(str(error))
		return messages
	pathfinder = GroundPathfinder.new(grid)
	if pathfinder.find_route(map).is_empty(): return PackedStringArray(["Initial Ground route is invalid"])
	phases = GamePhaseMachine.new(); phases.reset()
	wave = WaveRuntime.new()
	gem_generator = GemGenerator.new(foundation.random)
	mvp = MvpState.new()
	construction = ConstructionRuntime.new()
	construction.setup(grid, pathfinder, phases, gem_generator, foundation.catalog.recipes, map)
	construction.begin_round(1)
	combat = CombatRuntime.new()
	effects = EffectSystem.new()
	combat.effect_system = effects
	combat.setup(foundation.catalog.globals.projectile_speed, pathfinder.find_route(map))
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
	player_state = {"wave": 1, "lives": 1000, "max_lives": 1000, "score": 0, "gold": 0, "xp": 0, "player_level": 1, "progress": 50.0, "base_enemy_count": 10, "support_skills": {}}
	progress.changed.connect(func(value: float): player_state.progress = value)
	economy.changed.connect(func(value: int): player_state.gold = value)
	progression.changed.connect(func(value: int, quality: int): player_state.xp = value; player_state.player_level = quality)
	outcome.life_changed.connect(func(value: int): player_state.lives = value)
	outcome.defeated.connect(func(): outcome_state = "defeat")
	outcome.victorious.connect(func(): outcome_state = "victory")
	return PackedStringArray()

func start_first_wave() -> bool:
	if wave == null or wave.is_active(): return false
	if phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
		phases.resolve_construction()
	if phases.phase != GamePhaseMachine.Phase.COMBAT: return false
	var definition := wave_definitions[phases.wave_number - 1] as WaveDefinition
	var profile := foundation.catalog.enemy_profile_by_id(definition.enemy_profile_id) as EnemyProfileDefinition
	if profile == null: return false
	current_wave_is_boss = definition.boss
	definition.spawn_count = 1 if definition.boss else maxi(1, 10 + progress.future_count_modifier)
	player_state.base_enemy_count = definition.spawn_count
	wave.start(definition, profile)
	wave.wave_completed.connect(_on_wave_completed, CONNECT_ONE_SHOT)
	return true

func tick(delta: float) -> void:
	if phases != null and phases.phase == GamePhaseMachine.Phase.COMBAT and outcome_state == "playing":
		wave.tick(delta)
		combat.tick(delta)
		effects.tick(delta)

func _on_wave_enemy_spawned(wave_enemy_id: int, profile: EnemyProfileDefinition) -> void:
	var enemy := combat.spawn_enemy(profile, map.spawn)
	if enemy != null:
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
