class_name TowerCombatStats
extends RefCounted

const MIN_ATTACK_SPEED := 20.0
const MAX_ATTACK_SPEED := 700.0
var damage := 1.0
var range_units := 100.0
var base_attack_speed := 100.0
var bat := 1.0
var attack_speed_bonus := 0.0

static func from_gem(gem: GemInstance, definition: GemDefinition) -> TowerCombatStats:
	var result := TowerCombatStats.new()
	if definition == null: return result
	var selected: Dictionary = {}
	for level_data in definition.levels:
		if int(level_data.get("level", 1)) == gem.level: selected = level_data; break
	if selected.is_empty() and not definition.levels.is_empty(): selected = definition.levels[0]
	result.damage = float(selected.get("damage", 1.0))
	result.range_units = float(selected.get("range", 100.0))
	result.base_attack_speed = float(selected.get("base_attack_speed", selected.get("attack_speed", 100.0)))
	result.bat = maxf(float(selected.get("bat", 1.0)), 0.001)
	return result

func total_attack_speed() -> float:
	return clampf(base_attack_speed + attack_speed_bonus, MIN_ATTACK_SPEED, MAX_ATTACK_SPEED)

func attacks_per_second() -> float:
	return total_attack_speed() / (100.0 * bat)

func attack_interval() -> float:
	return (100.0 * bat) / total_attack_speed()
