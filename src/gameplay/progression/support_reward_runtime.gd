class_name SupportRewardRuntime
extends RefCounted

signal reward_available(wave_number: int, candidates: Array)
signal reward_chosen(skill_id: StringName, level: int)

const IDS: Array[StringName] = [&"fixed_hammer", &"reroll", &"swap", &"checkpoint_maker", &"curar"]
var catalog: SupportSkillCatalog
var random_source: RandomSource
var pending_wave := 0
var candidates: Array[StringName] = []

func setup(value_catalog: SupportSkillCatalog, value_random: RandomSource) -> void:
	catalog = value_catalog; random_source = value_random

func reset() -> void:
	pending_wave = 0; candidates.clear()

func generate_for_wave(wave_number: int) -> Array[StringName]:
	if wave_number <= 0 or wave_number >= 50 or wave_number % 5 != 0 or not candidates.is_empty(): return []
	var valid: Array[StringName] = []
	for skill_id in IDS:
		if not catalog.skills.has(skill_id) or int(catalog.skills[skill_id].level) < 4 or catalog.skills.size() < 4:
			valid.append(skill_id)
	var pool := valid.duplicate()
	candidates.clear()
	while not pool.is_empty() and candidates.size() < mini(3, valid.size()):
		var picked: Variant = random_source.pick(pool) if random_source != null else pool[0]
		candidates.append(picked); pool.erase(picked)
	pending_wave = wave_number
	reward_available.emit(wave_number, candidates.duplicate())
	return candidates.duplicate()

func choose(skill_id: StringName) -> RefCounted:
	if pending_wave == 0 or skill_id not in candidates: return null
	var skill: RefCounted = catalog.upgrade(skill_id) if catalog.skills.has(skill_id) else catalog.acquire(skill_id, 1)
	if skill == null: return null
	candidates.clear(); pending_wave = 0
	reward_chosen.emit(skill_id, skill.level)
	return skill
