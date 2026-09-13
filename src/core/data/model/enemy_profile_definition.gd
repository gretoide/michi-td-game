class_name EnemyProfileDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export_enum("Ground", "Flying") var movement_type: String = "Ground"
@export var hp: float = 1.0
@export var base_speed: float = 250.0
@export var armor: float = 0.0
@export var magic_resistance: float = 0.0
@export var attack: float = 1.0
@export var xp_reward: int = 0
@export var ability_ids: PackedStringArray = []
