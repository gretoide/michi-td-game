class_name FoundationRandomTest
extends RefCounted

const Random = preload("res://src/core/random/seeded_random_source.gd")
const Resolver = preload("res://src/core/random/seed_resolver.gd")

func run(suite: RefCounted) -> void:
	var first := Random.new(12345)
	var second := Random.new(12345)
	var sequence_a: Array[int] = []
	var sequence_b: Array[int] = []
	for _index in 8:
		sequence_a.append(first.next_int(1, 1000))
		sequence_b.append(second.next_int(1, 1000))
	suite.expect_equal(sequence_a, sequence_b, "Una seed debe reproducir la secuencia")
	var different := Random.new(54321)
	suite.expect(sequence_a != [different.next_int(1, 1000), different.next_int(1, 1000), different.next_int(1, 1000), different.next_int(1, 1000), different.next_int(1, 1000), different.next_int(1, 1000), different.next_int(1, 1000), different.next_int(1, 1000)], "Seeds distintas deben variar la secuencia")
	var picker := Random.new(9)
	var value = picker.pick_weighted(["a", "b"], [0.0, 1.0])
	suite.expect_equal(value, "b", "La selección ponderada debe respetar pesos")
	suite.expect_equal(Resolver.new().resolve(0, 123), 0, "La seed explícita cero debe ser válida")
