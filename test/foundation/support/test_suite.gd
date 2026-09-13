class_name FoundationTestSuite
extends RefCounted

var failures: Array[String] = []

func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func expect_equal(left: Variant, right: Variant, message: String) -> void:
	expect(left == right, "%s (got %s, expected %s)" % [message, left, right])
