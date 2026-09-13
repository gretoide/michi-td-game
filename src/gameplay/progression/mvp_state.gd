class_name MvpState
extends RefCounted

const MAX_LEVEL := 10
var levels: Dictionary = {}
var graduated: Dictionary = {}

func register_tower(tower_id: StringName) -> void:
	if not levels.has(tower_id):
		levels[tower_id] = 0

func level_of(tower_id: StringName) -> int:
	return int(levels.get(tower_id, 0))

func multiplier_of(tower_id: StringName) -> float:
	return 1.0 + minf(float(level_of(tower_id)), 9.0) * 0.10

func award(tower_id: StringName) -> int:
	register_tower(tower_id)
	var next := mini(level_of(tower_id) + 1, MAX_LEVEL)
	levels[tower_id] = next
	if next >= MAX_LEVEL:
		graduated[tower_id] = true
	return next

func is_graduated(tower_id: StringName) -> bool:
	return bool(graduated.get(tower_id, false))

func choose_winner(damage_by_tower: Dictionary, random: RandomSource = null) -> StringName:
	var best := -1.0
	var candidates: Array[StringName] = []
	for tower_id in damage_by_tower:
		var id := StringName(tower_id)
		if is_graduated(id):
			continue
		var damage := float(damage_by_tower[tower_id])
		if damage > best:
			best = damage; candidates = [id]
		elif is_equal_approx(damage, best):
			candidates.append(id)
	if candidates.is_empty():
		return &""
	return (random if random != null else SeededRandomSource.new(0)).pick(candidates)

func award_round(damage_by_tower: Dictionary, random: RandomSource = null) -> StringName:
	var winner := choose_winner(damage_by_tower, random)
	if winner != &"":
		award(winner)
	return winner

static func transfer_mvp(gems: Array, cap := MAX_LEVEL) -> int:
	var total := 0
	for gem: GemInstance in gems:
		total += gem.mvp_level
	return mini(total, cap)

