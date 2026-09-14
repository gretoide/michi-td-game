class_name SupportSkillCatalog
extends RefCounted

const SupportSkillRuntimeScript = preload("res://src/gameplay/progression/support_skill_runtime.gd")

const IDS: Array[StringName] = [&"fixed_hammer", &"reroll", &"swap", &"checkpoint_maker", &"curar"]
const COSTS := {&"fixed_hammer": [250, 150, 100, 75], &"reroll": [600, 500, 400, 300], &"swap": [400, 300, 250, 225], &"checkpoint_maker": [350, 275, 225, 200], &"curar": [400, 400, 400, 400]}
const COOLDOWNS := {&"fixed_hammer": [0.0, 0.0, 0.0, 0.0], &"reroll": [0.0, 0.0, 0.0, 0.0], &"swap": [0.0, 0.0, 0.0, 0.0], &"checkpoint_maker": [0.0, 0.0, 0.0, 0.0], &"curar": [0.0, 0.0, 0.0, 0.0]}
var skills: Dictionary = {}

func reset() -> void: skills.clear()

func acquire(skill_id: StringName, level := 1) -> RefCounted:
	if skill_id not in IDS or level < 1 or level > 4: return null
	if not skills.has(skill_id) and skills.size() >= 4: return null
	var skill := SupportSkillRuntimeScript.new()
	var index := level - 1
	var costs: Array = COSTS.get(skill_id, [])
	var cooldowns: Array = COOLDOWNS.get(skill_id, [])
	if not skill.setup(skill_id, level, int(costs[index]), float(cooldowns[index])): return null
	skills[skill_id] = skill; return skill

func upgrade(skill_id: StringName) -> RefCounted:
	if not skills.has(skill_id): return null
	var current: RefCounted = skills[skill_id]
	return acquire(skill_id, current.level + 1)
