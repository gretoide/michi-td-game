class_name EnemyNavigator
extends RefCounted

signal checkpoint_reached(index: int)
signal finished

var position := Vector2.ZERO
var speed := 100.0
var _targets: Array[Vector2] = []
var _target_index := 0

func setup(cells: Array[Vector2i], grid: GridModel, movement_speed: float) -> void:
	_targets.clear()
	for cell in cells: _targets.append(grid.cell_to_world(cell))
	position = _targets[0] if not _targets.is_empty() else Vector2.ZERO
	_target_index = 1; speed = movement_speed

func tick(delta: float) -> void:
	if _target_index >= _targets.size(): return
	position = position.move_toward(_targets[_target_index], speed * delta)
	if position.is_equal_approx(_targets[_target_index]):
		var reached := _target_index; _target_index += 1
		if _target_index >= _targets.size(): finished.emit()
		else: checkpoint_reached.emit(reached - 1)

func is_finished() -> bool:
	return _target_index >= _targets.size()

static func flying_cells(layout: MapLayout) -> Array[Vector2i]:
	return layout.ordered_waypoints()
