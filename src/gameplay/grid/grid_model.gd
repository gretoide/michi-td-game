class_name GridModel
extends RefCounted

enum CellState { FREE, OCCUPIED, BLOCKED }

const WIDTH := 36
const HEIGHT := 36
const CELL_SIZE := 100.0

var _states: Dictionary = {}
var _reserved: Dictionary = {}
var revision := 0

func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < WIDTH and cell.y < HEIGHT

func state_at(cell: Vector2i) -> CellState:
	if not is_in_bounds(cell): return CellState.BLOCKED
	return _states.get(cell, CellState.FREE) as CellState

func is_walkable(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and state_at(cell) == CellState.FREE

func occupy(cell: Vector2i) -> bool:
	if not is_walkable(cell) or is_reserved(cell): return false
	_states[cell] = CellState.OCCUPIED; revision += 1; return true

func reserve(cell: Vector2i) -> bool:
	if not is_in_bounds(cell) or not is_walkable(cell): return false
	_reserved[cell] = true; revision += 1; return true

func is_reserved(cell: Vector2i) -> bool:
	return _reserved.has(cell)

func block(cell: Vector2i) -> bool:
	if not is_walkable(cell): return false
	_states[cell] = CellState.BLOCKED; revision += 1; return true

func release(cell: Vector2i) -> bool:
	if not is_in_bounds(cell) or state_at(cell) == CellState.FREE: return false
	_states.erase(cell); revision += 1; return true

func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	for offset: Vector2i in offsets:
		var candidate: Vector2i = cell + offset
		if is_in_bounds(candidate): result.append(candidate)
	return result

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * CELL_SIZE + Vector2.ONE * CELL_SIZE * 0.5

func world_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / CELL_SIZE), floori(position.y / CELL_SIZE))

func clear() -> void:
	_states.clear(); _reserved.clear(); revision += 1
