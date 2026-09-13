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
	player_state = {"wave": 1, "lives": 1000, "max_lives": 1000, "score": 0, "gold": 0, "xp": 0, "player_level": 1, "progress": 50.0, "base_enemy_count": 10, "support_skills": {}}
	return PackedStringArray()

func start_first_wave() -> bool:
	if phases.phase != GamePhaseMachine.Phase.CONSTRUCTION: return false
	var definition := foundation.catalog.waves[0] as WaveDefinition
	var profile := foundation.catalog.enemy_profiles[0] as EnemyProfileDefinition
	phases.resolve_construction(); wave.start(definition, profile)
	wave.wave_completed.connect(_on_wave_completed, CONNECT_ONE_SHOT)
	return true

func _on_wave_completed() -> void:
	phases.resolve_combat(); player_state.wave = phases.wave_number
