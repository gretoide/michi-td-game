class_name GameRuntime
extends RefCounted

const MAP_PATH := "res://data/gameplay/initial_map.tres"

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
var player_state: Dictionary

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
	wave.enemy_spawned.connect(_on_wave_enemy_spawned)
	construction.construction_finalized.connect(_on_construction_finalized)
	player_state = {"wave": 1, "lives": 1000, "max_lives": 1000, "score": 0, "gold": 0, "xp": 0, "player_level": 1, "progress": 50.0, "base_enemy_count": 10, "support_skills": {}}
	return PackedStringArray()

func start_first_wave() -> bool:
	if wave == null or wave.is_active(): return false
	if phases.phase == GamePhaseMachine.Phase.CONSTRUCTION:
		phases.resolve_construction()
	if phases.phase != GamePhaseMachine.Phase.COMBAT: return false
	var definition := foundation.catalog.waves[0] as WaveDefinition
	var profile := foundation.catalog.enemy_profiles[0] as EnemyProfileDefinition
	wave.start(definition, profile)
	wave.wave_completed.connect(_on_wave_completed, CONNECT_ONE_SHOT)
	return true

func tick(delta: float) -> void:
	if phases != null and phases.phase == GamePhaseMachine.Phase.COMBAT:
		wave.tick(delta)
		combat.tick(delta)
		effects.tick(delta)

func _on_wave_enemy_spawned(_id: int, profile: EnemyProfileDefinition) -> void:
	var enemy := combat.spawn_enemy(profile, map.spawn)
	if enemy != null:
		enemy.died.connect(func(): wave.resolve_enemy(enemy.id, &"death"))
		enemy.escaped.connect(func(): wave.resolve_enemy(enemy.id, &"escaped"))

func _sync_combat_towers() -> void:
	if combat == null: return
	combat.towers.clear()
	for gem: GemInstance in construction.board_gems:
		var definition := foundation.catalog.gem_by_id(gem.id) as GemDefinition
		var tower := TowerRuntime.new(); tower.setup(gem, definition, Vector2(gem.cell) * 100.0 + Vector2.ONE * 50.0); combat.add_tower(tower)

func _on_construction_finalized(_result: GemInstance) -> void:
	_sync_combat_towers()
	start_first_wave()

func _on_wave_completed() -> void:
	phases.resolve_combat(); player_state.wave = phases.wave_number
