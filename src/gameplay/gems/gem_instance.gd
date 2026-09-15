class_name GemInstance
extends RefCounted

enum Quality { CHIPPED = 1, FLAWED = 2, NORMAL = 3, FLAWLESS = 4, PERFECT = 5, IMPERIAL = 6, ROYAL = 7 }

var id: StringName
var level: int
var quality: Quality
var cell := Vector2i(-1, -1)
var round_id := 0
var mvp_level := 0

func _init(gem_id: StringName = &"", gem_level: int = 1, gem_quality: Quality = Quality.CHIPPED) -> void:
	id = gem_id
	level = clampi(gem_level, 1, 7)
	quality = gem_quality

func clone() -> GemInstance:
	var result := GemInstance.new(id, level, quality)
	result.cell = cell
	result.round_id = round_id
	result.mvp_level = mvp_level
	return result

func is_on_board() -> bool:
	return cell.x >= 0 and cell.y >= 0
