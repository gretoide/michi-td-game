class_name FoundationIntegrationTest
extends RefCounted

const Foundation = preload("res://src/core/bootstrap/gameplay_foundation.gd")

func run(suite: RefCounted) -> void:
	var foundation := Foundation.new()
	var result := foundation.initialize(777)
	suite.expect(result.is_valid(), "Foundation debe inicializar con catálogo válido")
	suite.expect(foundation.random != null, "Foundation debe construir el RNG compartido")
	if foundation.random != null:
		suite.expect_equal(foundation.random.next_int(0, 0), 0, "RNG debe respetar rangos cerrados")
