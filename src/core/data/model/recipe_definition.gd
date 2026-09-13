class_name RecipeDefinition
extends Resource

@export var id: StringName
@export var result_id: StringName
@export var ability_ids: PackedStringArray = []
@export var ingredients: Array[Dictionary] = []
@export var secret: bool = false
@export var range_units: float = 0.0
@export var damage: float = 0.0
@export var attack_speed: float = 0.0
