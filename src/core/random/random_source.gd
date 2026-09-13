class_name RandomSource
extends RefCounted

func next_int(min_value: int, max_value: int) -> int:
	push_error("RandomSource.next_int debe ser implementado")
	return min_value

func next_float() -> float:
	push_error("RandomSource.next_float debe ser implementado")
	return 0.0

func pick(values: Array) -> Variant:
	if values.is_empty():
		return null
	return values[next_int(0, values.size() - 1)]

func pick_weighted(values: Array, weights: Array[float]) -> Variant:
	if values.is_empty() or values.size() != weights.size():
		return null
	var total := 0.0
	for weight in weights:
		if weight < 0.0:
			return null
		total += weight
	if total <= 0.0:
		return null
	var cursor := next_float() * total
	for index in values.size():
		cursor -= weights[index]
		if cursor < 0.0:
			return values[index]
	return values.back()
