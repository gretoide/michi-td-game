extends Node

signal locale_changed(locale: String)
const DEFAULT_LOCALE := "en"
const SUPPORTED_LOCALES := ["en", "es"]
var locale := DEFAULT_LOCALE
var diagnostics := PackedStringArray()
var _catalog := {
    "en": {"landing.title":"Welcome to the kingdom", "landing.hint":"Choose how you want to begin your adventure", "landing.create":"Create account", "landing.login":"Log in", "welcome.title":"Welcome, {alias}", "welcome.info":"Your account is ready. Prepare your defenses for the next battle.", "welcome.enter":"Enter the kingdom", "welcome.logout":"Log out", "auth.register.title":"Create account", "auth.login.title":"Log in", "auth.register.submit":"Sign up", "auth.login.submit":"Enter", "auth.back":"Back", "auth.alias":"Alias", "auth.email":"Email", "auth.password":"Password", "auth.register.prompt":"First time in the kingdom?", "auth.login.prompt":"Already defended this kingdom?", "auth.register.action":"Create account", "auth.login.action":"Log in", "session.restoring":"Restoring your session...", "music.pause":"Pause music", "music.play":"Play music", "locale.label":"Language", "verification.title":"Confirm your email", "verification.code_label":"Verification code", "verification.code_placeholder":"Enter the 6 digits", "verification.confirm":"Confirm code", "verification.resend":"Resend code", "verification.invalid_code":"Enter a valid 6-digit code", "verification.resent":"Code resent. Check your inbox."},
    "es": {"landing.title":"Bienvenido al reino", "landing.hint":"Elegí cómo querés comenzar tu aventura", "landing.create":"Crear cuenta", "landing.login":"Iniciar sesión", "welcome.title":"Bienvenido, {alias}", "welcome.info":"Tu cuenta está lista. Prepará tus defensas para la próxima batalla.", "welcome.enter":"Entrar al reino", "welcome.logout":"Cerrar sesión", "auth.register.title":"Crear cuenta", "auth.login.title":"Iniciar sesión", "auth.register.submit":"Registrarme", "auth.login.submit":"Entrar", "auth.back":"Volver", "auth.alias":"Alias", "auth.email":"Email", "auth.password":"Contraseña", "auth.register.prompt":"¿Primera vez en el reino?", "auth.login.prompt":"¿Ya defendiste este reino?", "auth.register.action":"Crear cuenta", "auth.login.action":"Iniciar sesión", "session.restoring":"Reconociendo tu sesión...", "music.pause":"Pausar música", "music.play":"Reproducir música", "locale.label":"Idioma", "verification.title":"Confirmá tu email", "verification.code_label":"Código de verificación", "verification.code_placeholder":"Ingresá los 6 dígitos", "verification.confirm":"Confirmar código", "verification.resend":"Reenviar código", "verification.invalid_code":"Ingresá un código válido de 6 dígitos", "verification.resent":"Código reenviado. Revisá tu bandeja de entrada."}
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
        "game.phase.construction": "Construction", "game.phase.combat": "Combat", "game.phase.victory": "Victory", "game.phase.defeat": "Defeat",
        "game.wave": "Wave {number}", "game.pause": "Pause", "game.pause.title": "Game paused", "game.pause.message": "The game is paused.", "game.pause.resume": "Resume", "game.pause.main_menu": "Main menu", "game.pause.logout": "Log out", "game.pause.exit": "Exit game", "game.pause.confirm_main_menu": "Return to main menu?", "game.pause.confirm_logout": "Log out?", "game.pause.confirm_exit": "Exit the game?", "game.pause.confirm_message": "Your current construction will be abandoned.", "game.pause.confirm": "Continue", "game.pause.cancel": "Cancel", "game.resources.life": "Life", "game.resources.gold": "Gold", "game.resources.full": "Life {life}/{max_life} | Gold {gold} | XP {xp} | Quality {quality} | Progress {progress}", "game.resources.compact": "Life {life}/{max_life} · Gold {gold} · XP {xp} · Q {quality} · {progress}%",
        "game.command.title": "Command card", "game.command.place_gem": "Place", "game.command.select_gem": "Select", "game.command.combine": "Combine", "game.command.degrade": "Degrade", "game.command.remove_stone": "Remove stone", "game.command.attack": "Attack", "game.command.stop": "Stop", "game.command.recipes": "Recipes", "game.command.keep_gem": "Keep", "game.command.debug": "Debug", "game.command.settings": "Settings", "game.command.restart": "Restart",
        "game.selection.none": "Nothing selected", "game.selection.selected": "Selected: {kind}", "game.selection.gem": "Gem {id} | Level {level} | Quality {quality} | Cell {cell}", "game.selection.enemy": "Enemy {id} | HP {hp}/{max_hp} | Armor {armor} | MR {magic}", "game.selection.tower": "Gem {id} | Damage {damage} | Range {range} | Stopped: {stopped}", "game.selection.stone": "Stone selected", "game.feedback.help": "Click a cell to place or select a gem.", "game.feedback.place_hint": "Choose an empty cell on the map.", "game.feedback.select_hint": "Click a gem or enemy to inspect it.", "game.feedback.no_combination": "No valid combination for this selection.", "game.feedback.invalid_action": "This action is not available.",
        "game.recipes.title": "Known recipes", "game.recipes.color.all": "All colors", "game.recipes.color.blue": "Blue", "game.recipes.color.dark_blue": "Dark blue", "game.recipes.color.gold": "Gold", "game.recipes.color.light_green": "Green", "game.recipes.color.lilac": "Lilac", "game.recipes.color.purple": "Purple", "game.recipes.color.red": "Red", "game.recipes.color.turquoise": "Turquoise", "game.close": "Close", "game.reward.title": "Reward after wave {wave}", "game.reward.skill.fixed_hammer": "Fixed hammer", "game.reward.skill.reroll": "Reroll", "game.reward.skill.swap": "Swap", "game.reward.skill.checkpoint_maker": "Checkpoint maker", "game.reward.skill.curar": "Heal", "game.end.victory": "Victory", "game.end.defeat": "Defeat", "game.end.score": "Final score: {score}", "game.restart": "Restart", "game.settings.title": "Settings", "game.settings.fullscreen": "Fullscreen", "game.settings.music_enabled": "Music on", "game.settings.music": "Music volume", "game.settings.sfx": "Effects volume", "game.settings.text_size": "Text size", "game.settings.text_small": "Small", "game.settings.text_normal": "Normal", "game.settings.text_large": "Large", "game.debug.title": "Debug information", "game.debug.info": "Seed: {seed}\nCatalog: {gems} gems · {recipes} recipes · {waves} waves",
        "game.harness.title": "Construction harness", "game.harness.select": "Select Gem", "game.harness.select_gem": "Select gem", "game.harness.place": "Place Gem", "game.harness.combine": "Combine basic", "game.harness.degrade": "Degrade", "game.harness.degrade_hint": "Select a non-Chipped gem", "game.harness.remove": "Remove Stone", "game.harness.status": "Gems {gems}/5 | Stones {stones} | Phase {phase}", "game.harness.rejected": "Rejected: {code}", "game.harness.finalized": "Construction finalized", "game.combat.summary": "Gems {towers} | Enemies {enemies} | Projectiles {projectiles}", "game.resources": "Life {life} | Gold {gold} | XP {xp} | Progress {progress}"
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
        "game.phase.construction": "Construcción", "game.phase.combat": "Combate", "game.phase.victory": "Victoria", "game.phase.defeat": "Derrota",
        "game.wave": "Oleada {number}", "game.pause": "Pausa", "game.pause.title": "Partida pausada", "game.pause.message": "La partida está en pausa.", "game.pause.resume": "Continuar", "game.pause.main_menu": "Menú principal", "game.pause.logout": "Cerrar sesión", "game.pause.exit": "Salir del juego", "game.pause.confirm_main_menu": "¿Volver al menú principal?", "game.pause.confirm_logout": "¿Cerrar sesión?", "game.pause.confirm_exit": "¿Salir del juego?", "game.pause.confirm_message": "La construcción actual se va a abandonar.", "game.pause.confirm": "Continuar", "game.pause.cancel": "Cancelar", "game.resources.life": "Vida", "game.resources.gold": "Oro", "game.resources.full": "Vida {life}/{max_life} | Oro {gold} | XP {xp} | Calidad {quality} | Progreso {progress}", "game.resources.compact": "Vida {life}/{max_life} · Oro {gold} · XP {xp} · C {quality} · {progress}%",
        "game.command.title": "Carta de comandos", "game.command.place_gem": "Colocar", "game.command.select_gem": "Seleccionar", "game.command.combine": "Combinar", "game.command.degrade": "Degradar", "game.command.remove_stone": "Quitar piedra", "game.command.attack": "Atacar", "game.command.stop": "Detener", "game.command.recipes": "Recetas", "game.command.keep_gem": "Conservar", "game.command.debug": "Debug", "game.command.settings": "Ajustes", "game.command.restart": "Reiniciar",
        "game.selection.none": "Nada seleccionado", "game.selection.selected": "Seleccionado: {kind}", "game.selection.gem": "Gema {id} | Nivel {level} | Calidad {quality} | Celda {cell}", "game.selection.enemy": "Enemigo {id} | HP {hp}/{max_hp} | Armadura {armor} | MR {magic}", "game.selection.tower": "Gema {id} | Daño {damage} | Rango {range} | Detenida: {stopped}", "game.selection.stone": "Piedra seleccionada", "game.feedback.help": "Hacé click en una celda para colocar o seleccionar una gema.", "game.feedback.place_hint": "Elegí una celda libre del mapa.", "game.feedback.select_hint": "Hacé click en una gema o enemigo para inspeccionarlo.", "game.feedback.no_combination": "No hay una combinación válida para esta selección.", "game.feedback.invalid_action": "Esta acción no está disponible.",
        "game.recipes.title": "Recetas conocidas", "game.recipes.color.all": "Todos los colores", "game.recipes.color.blue": "Azul", "game.recipes.color.dark_blue": "Azul oscuro", "game.recipes.color.gold": "Dorado", "game.recipes.color.light_green": "Verde", "game.recipes.color.lilac": "Lila", "game.recipes.color.purple": "Violeta", "game.recipes.color.red": "Rojo", "game.recipes.color.turquoise": "Turquesa", "game.close": "Cerrar", "game.reward.title": "Recompensa después de la oleada {wave}", "game.reward.skill.fixed_hammer": "Martillo fijo", "game.reward.skill.reroll": "Volver a tirar", "game.reward.skill.swap": "Intercambiar", "game.reward.skill.checkpoint_maker": "Crear punto de control", "game.reward.skill.curar": "Curar", "game.end.victory": "Victoria", "game.end.defeat": "Derrota", "game.end.score": "Puntaje final: {score}", "game.restart": "Reiniciar", "game.settings.title": "Configuración", "game.settings.fullscreen": "Pantalla completa", "game.settings.music_enabled": "Música activada", "game.settings.music": "Volumen de música", "game.settings.sfx": "Volumen de efectos", "game.settings.text_size": "Tamaño del texto", "game.settings.text_small": "Pequeño", "game.settings.text_normal": "Normal", "game.settings.text_large": "Grande", "game.debug.title": "Información de depuración", "game.debug.info": "Semilla: {seed}\nCatálogo: {gems} gemas · {recipes} recetas · {waves} oleadas",
        "game.harness.title": "Panel de construcción", "game.harness.select": "Seleccionar gema", "game.harness.select_gem": "Seleccioná una gema", "game.harness.place": "Colocar gema", "game.harness.combine": "Combinar básica", "game.harness.degrade": "Degradar", "game.harness.degrade_hint": "Seleccioná una gema no Chipped", "game.harness.remove": "Eliminar piedra", "game.harness.status": "Gemas {gems}/5 | Piedras {stones} | Fase {phase}", "game.harness.rejected": "Rechazado: {code}", "game.harness.finalized": "Construcción finalizada", "game.combat.summary": "Gemas {towers} | Enemigos {enemies} | Proyectiles {projectiles}", "game.resources": "Vida {life} | Oro {gold} | XP {xp} | Progreso {progress}"
    }
}

const GAMEPLAY_EXTRA := {
    "en": {"game.help.title":"Gameplay guide", "game.help.actions":"Actions", "game.help.shortcuts":"Keyboard shortcuts", "game.help.shortcut_escape":"Close the open panel or clear selection", "game.quality.1":"Chipped", "game.quality.2":"Flawed", "game.quality.3":"Normal", "game.quality.4":"Flawless", "game.quality.5":"Perfect", "game.quality.6":"Imperial", "game.quality.7":"Royal", "game.state.stopped":"Stopped", "game.state.active":"Active", "game.help.place":"Place: hover a free cell during Construction and click to place a gem. Available while building. Result: the gem occupies that cell.", "game.help.select":"Select: click a gem, stone or enemy to inspect it. Available any time the map is active.", "game.help.combine":"Combine: merge matching gems when construction is complete. Result: matching ingredients become one advanced gem.", "game.help.degrade":"Degrade: lower a selected gem's level to change its quality. The selected cell remains occupied.", "game.help.remove_stone":"Remove stone: free a cell occupied by a discarded gem. Available when a stone is selected.", "game.help.keep":"Keep: finish construction with the selected gem and start combat.", "game.help.restart":"Restart: clear only this wave's construction, preserving earlier waves and player progress.", "game.help.search":"Search", "game.help.empty":"No recipes match your filters.", "game.recipes.filter.all":"All", "game.recipes.filter.base":"Base gems", "game.recipes.filter.advanced":"Advanced gems", "game.recipes.filter.level":"Level", "game.tooltip.gem":"Gem {id} | Level {level} | Quality {quality} | Cell {cell}", "game.tooltip.tower":"Gem {id} | Damage {damage} | Range {range} | State: {stopped}"},
    "es": {"game.help.title":"Guía de juego", "game.help.actions":"Acciones", "game.help.shortcuts":"Atajos de teclado", "game.help.shortcut_escape":"Cierra el panel abierto o limpia la selección", "game.quality.1":"Rota", "game.quality.2":"Defectuosa", "game.quality.3":"Normal", "game.quality.4":"Impecable", "game.quality.5":"Perfecta", "game.quality.6":"Imperial", "game.quality.7":"Real", "game.state.stopped":"Detenida", "game.state.active":"Activa", "game.help.place":"Colocar: pasá sobre una celda libre durante Construcción y hacé click para poner una gema. Disponible mientras construís. Resultado: la gema ocupa esa celda.", "game.help.select":"Seleccionar: hacé click en una gema, piedra o enemigo para inspeccionarlo. Disponible con el mapa activo.", "game.help.combine":"Combinar: uní gemas iguales cuando la construcción esté completa. Resultado: los ingredientes se convierten en una gema avanzada.", "game.help.degrade":"Degradar: bajá el nivel de una gema seleccionada para cambiar su calidad. La celda sigue ocupada.", "game.help.remove_stone":"Quitar piedra: liberá una celda ocupada por una gema descartada. Disponible al seleccionar una piedra.", "game.help.keep":"Conservar: terminá la construcción con la gema seleccionada y empezá el combate.", "game.help.restart":"Reiniciar: limpiá solo la construcción de esta oleada y preservá las oleadas anteriores y el progreso.", "game.help.search":"Buscar", "game.help.empty":"No hay recetas con esos filtros.", "game.recipes.filter.all":"Todas", "game.recipes.filter.base":"Gemas base", "game.recipes.filter.advanced":"Gemas avanzadas", "game.recipes.filter.level":"Nivel", "game.tooltip.gem":"Gema {id} | Nivel {level} | Calidad {quality} | Celda {cell}", "game.tooltip.tower":"Gema {id} | Daño {damage} | Rango {range} | Estado: {stopped}"}
}

func _init() -> void:
    for supported in SUPPORTED_LOCALES: _catalog[supported].merge(EXTRA_CATALOG[supported], true)
    for supported in SUPPORTED_LOCALES: _catalog[supported].merge(GAMEPLAY_EXTRA[supported], true)

func _ready() -> void:
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
