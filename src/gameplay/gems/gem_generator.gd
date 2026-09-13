class_name GemGenerator
extends RefCounted

const GEM_IDS: Array[StringName] = [&"amethyst", &"aquamarine", &"diamond", &"emerald", &"opal", &"ruby", &"sapphire", &"topaz"]
const QUALITY_TABLE := {
	1: [100.0, 0.0, 0.0, 0.0, 0.0],
	2: [70.0, 30.0, 0.0, 0.0, 0.0],
	3: [60.0, 30.0, 10.0, 0.0, 0.0],
	4: [40.0, 30.0, 20.0, 10.0, 0.0],
	5: [10.0, 30.0, 30.0, 20.0, 10.0]
}

var random: RandomSource
var round_id := 0
var generated_this_round := 0

func _init(source: RandomSource = null) -> void:
	random = source if source != null else SeededRandomSource.new(0)

func reset_round(value := 0) -> void:
	round_id = value
	generated_this_round = 0

func generate(player_level: int = 1) -> GemInstance:
	if generated_this_round >= 5:
		return null
	var gem := GemInstance.new(random.pick(GEM_IDS), 1, _roll_quality(player_level))
	gem.round_id = round_id
	generated_this_round += 1
	return gem

func _roll_quality(player_level: int) -> GemInstance.Quality:
	var level := clampi(player_level, 1, 5)
	var weights: Array[float] = []
	for value in QUALITY_TABLE[level]:
		weights.append(float(value))
	return int(random.pick_weighted([1, 2, 3, 4, 5], weights)) as GemInstance.Quality

static func quality_probabilities(player_level: int) -> Array[float]:
	var result: Array[float] = []
	for value in QUALITY_TABLE[clampi(player_level, 1, 5)]:
		result.append(float(value))
	return result
