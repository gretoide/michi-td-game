extends RefCounted

const LocalizationServiceScript = preload("res://src/core/localization/localization_service.gd")

func run(suite: FoundationTestSuite) -> void:
	var localization = LocalizationServiceScript.new()
	localization._ready()
	localization.locale = "en"
	suite.expect_equal(localization.tr_key("auth.password"), "Password", "English auth fields use the English catalog")
	localization.locale = "es"
	suite.expect_equal(localization.tr_key("auth.password"), "Contraseña", "Spanish auth fields use the Spanish catalog")
	suite.expect(localization.validate_catalog().is_empty(), "every runtime key has en and es translations")
	var spanish: Dictionary = localization._catalog["es"]
	var original = spanish["auth.password"]
	spanish.erase("auth.password")
	localization.diagnostics.clear()
	suite.expect_equal(localization.tr_key("auth.password"), "Password", "missing Spanish key falls back to English")
	suite.expect_equal(localization.diagnostics.size(), 1, "missing translation records one diagnostic")
	spanish["auth.password"] = original
	localization.free()
