extends Node

signal locale_changed(locale: String)
const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES := ["en", "es"]
var locale := DEFAULT_LOCALE
var diagnostics := PackedStringArray()
var _catalog := {
    "en": {"landing.title":"Welcome to the kingdom", "landing.hint":"Choose how you want to begin your adventure", "landing.create":"Create account", "landing.login":"Log in", "auth.register.title":"Create account", "auth.login.title":"Log in", "auth.register.submit":"Sign up", "auth.login.submit":"Enter", "auth.back":"Back", "auth.alias":"Alias", "auth.email":"Email", "auth.password":"Password", "auth.register.prompt":"First time in the kingdom?", "auth.login.prompt":"Already defended this kingdom?", "auth.register.action":"Create account", "auth.login.action":"Log in", "session.restoring":"Restoring your session...", "music.pause":"Pause music", "music.play":"Play music", "locale.label":"Language", "verification.title":"Confirm your email", "verification.code_label":"Verification code", "verification.code_placeholder":"Enter the 6 digits", "verification.confirm":"Confirm code", "verification.resend":"Resend code", "verification.invalid_code":"Enter a valid 6-digit code", "verification.resent":"Code resent. Check your inbox."},
    "es": {"landing.title":"Bienvenido al reino", "landing.hint":"Elegí cómo querés comenzar tu aventura", "landing.create":"Crear cuenta", "landing.login":"Iniciar sesión", "auth.register.title":"Crear cuenta", "auth.login.title":"Iniciar sesión", "auth.register.submit":"Registrarme", "auth.login.submit":"Entrar", "auth.back":"Volver", "auth.alias":"Alias", "auth.email":"Email", "auth.password":"Contraseña", "auth.register.prompt":"¿Primera vez en el reino?", "auth.login.prompt":"¿Ya defendiste este reino?", "auth.register.action":"Crear cuenta", "auth.login.action":"Iniciar sesión", "session.restoring":"Reconociendo tu sesión...", "music.pause":"Pausar música", "music.play":"Reproducir música", "locale.label":"Idioma", "verification.title":"Confirmá tu email", "verification.code_label":"Código de verificación", "verification.code_placeholder":"Ingresá los 6 dígitos", "verification.confirm":"Confirmar código", "verification.resend":"Reenviar código", "verification.invalid_code":"Ingresá un código válido de 6 dígitos", "verification.resent":"Código reenviado. Revisá tu bandeja de entrada."}
}

const EXTRA_CATALOG := {
    "en": {
        "verification.hint": "We sent a code to {email}\nIt is valid for 15 minutes.",
        "error.alias_used": "That alias or email is already in use. Try another one or log in.",
        "error.alias_chars": "The alias may only contain letters, numbers, spaces, hyphens and underscores.",
        "error.alias_length": "The alias must contain at least 3 characters.",
        "error.email_invalid": "Enter a valid email.",
        "error.password_length": "The password must contain at least 8 characters.",
        "error.credentials": "The email or password is incorrect.",
        "error.code_invalid_expired": "That code is no longer valid. Request a new one.",
        "error.code_invalid": "The code does not match. Check it and try again.",
        "error.code_expired": "The code expired. Request a new one.",
        "error.code_attempts": "You reached the attempt limit. Resend the code to generate a new one.",
        "error.code_cooldown": "The code was sent recently. Wait one minute before requesting another.",
        "error.email_config": "The server has not configured email delivery yet.",
        "error.email_delivery": "We could not send the email code. Try again in a few minutes.",
        "error.request_busy": "Another operation is running. Wait a moment and try again.",
        "error.network": "We could not connect to the server. Check your connection and try again.",
        "error.unexpected": "An unexpected error occurred. Try again.",
        "error.game_start": "The game could not start: {detail}"
        ,"password.show": "Show password", "password.hide": "Hide password",
        "game.phase.construction": "Construction", "game.phase.combat": "Combat",
        "game.wave": "Wave {number}", "game.pause": "Pause",
        "game.harness.title": "Construction harness", "game.harness.select": "Select Gem", "game.harness.select_gem": "Select gem", "game.harness.place": "Place Gem", "game.harness.keep": "Keep first", "game.harness.combine": "Combine basic", "game.harness.degrade": "Degrade", "game.harness.remove": "Remove Stone", "game.harness.status": "Gems {gems}/5 | Stones {stones} | Phase {phase}", "game.harness.rejected": "Rejected: {code}", "game.harness.finalized": "Construction finalized", "game.combat.summary": "Towers {towers} | Enemies {enemies} | Projectiles {projectiles}"
    },
    "es": {
        "verification.hint": "Enviamos un código a {email}\nTiene una validez de 15 minutos.",
        "error.alias_used": "Ese alias o email ya está en uso. Probá con otro o iniciá sesión.",
        "error.alias_chars": "El alias sólo puede contener letras, números, espacios, guiones y guion bajo.",
        "error.alias_length": "El alias debe tener al menos 3 caracteres.",
        "error.email_invalid": "Ingresá un email válido.",
        "error.password_length": "La contraseña debe tener al menos 8 caracteres.",
        "error.credentials": "El email o la contraseña no son correctos.",
        "error.code_invalid_expired": "Ese código ya no es válido. Pedí uno nuevo.",
        "error.code_invalid": "El código ingresado no coincide. Revisalo e intentá nuevamente.",
        "error.code_expired": "El código venció. Pedí uno nuevo.",
        "error.code_attempts": "Alcanzaste el límite de intentos. Reenviá el código para generar uno nuevo.",
        "error.code_cooldown": "El código se envió hace poco. Esperá un minuto antes de pedir otro.",
        "error.email_config": "El servidor todavía no tiene configurado el envío de emails.",
        "error.email_delivery": "No pudimos enviar el código por email. Intentá nuevamente en unos minutos.",
        "error.request_busy": "Hay otra operación en curso. Esperá un momento e intentá nuevamente.",
        "error.network": "No pudimos conectar con el servidor. Revisá tu conexión e intentá nuevamente.",
        "error.unexpected": "Ocurrió un error inesperado. Intentá nuevamente.",
        "error.game_start": "No se pudo iniciar la partida: {detail}"
        ,"password.show": "Mostrar contraseña", "password.hide": "Ocultar contraseña",
        "game.phase.construction": "Construcción", "game.phase.combat": "Combate",
        "game.wave": "Oleada {number}", "game.pause": "Pausa",
        "game.harness.title": "Panel de construcción", "game.harness.select": "Seleccionar gema", "game.harness.select_gem": "Seleccioná una gema", "game.harness.place": "Colocar gema", "game.harness.keep": "Conservar primera", "game.harness.combine": "Combinar básica", "game.harness.degrade": "Degradar", "game.harness.remove": "Eliminar piedra", "game.harness.status": "Gemas {gems}/5 | Piedras {stones} | Fase {phase}", "game.harness.rejected": "Rechazado: {code}", "game.harness.finalized": "Construcción finalizada", "game.combat.summary": "Torres {towers} | Enemigos {enemies} | Proyectiles {projectiles}"
    }
}

func _ready() -> void:
    for supported in SUPPORTED_LOCALES: _catalog[supported].merge(EXTRA_CATALOG[supported], true)
    load_local_preference()

func set_locale(value: String) -> void:
    var next := value.to_lower()
    if next not in SUPPORTED_LOCALES: next = DEFAULT_LOCALE
    if locale == next: return
    locale = next; save_local_preference(); locale_changed.emit(locale)

func tr_key(key: String, values: Dictionary = {}) -> String:
    var selected: Dictionary = _catalog.get(locale, {})
    var english: Dictionary = _catalog[DEFAULT_LOCALE]
    if not selected.has(key):
        _record_missing_key(locale, key)
    if not english.has(key):
        _record_missing_key(DEFAULT_LOCALE, key)
    var result := str(selected.get(key, english.get(key, key)))
    for name in values: result = result.replace("{" + str(name) + "}", str(values[name]))
    return result

func validate_catalog() -> PackedStringArray:
    var errors := PackedStringArray()
    var english: Dictionary = _catalog.get(DEFAULT_LOCALE, {})
    for key in english:
        for supported in SUPPORTED_LOCALES:
            var translations: Dictionary = _catalog.get(supported, {})
            if not translations.has(key) or str(translations[key]).strip_edges().is_empty():
                errors.append("Missing translation '%s' for locale '%s'" % [key, supported])
    for supported in SUPPORTED_LOCALES:
        var translations: Dictionary = _catalog.get(supported, {})
        for key in translations:
            if not english.has(key):
                errors.append("Translation '%s' for locale '%s' has no English fallback" % [key, supported])
    return errors

func _record_missing_key(target_locale: String, key: String) -> void:
    var diagnostic := "Missing localization key '%s' for locale '%s'" % [key, target_locale]
    if diagnostic in diagnostics:
        return
    diagnostics.append(diagnostic)
    if OS.is_debug_build():
        push_warning(diagnostic)

func load_local_preference() -> void:
    var config := ConfigFile.new()
    if config.load("user://preferences.cfg") == OK:
        var stored := str(config.get_value("preferences", "locale", DEFAULT_LOCALE))
        locale = stored if stored in SUPPORTED_LOCALES else DEFAULT_LOCALE

func save_local_preference() -> void:
    var config := ConfigFile.new(); config.set_value("preferences", "locale", locale); config.save("user://preferences.cfg")
