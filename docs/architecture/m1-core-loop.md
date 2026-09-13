# M1 — Core TD Loop

## Runtime

M1 introduce una partida nueva y descartable después de cualquier autenticación válida. `GameRuntime` compone una `GridModel` 36×36, el `MapLayout` canónico, navegación, fases y `WaveRuntime`; nunca restaura estado de gameplay desde la sesión de cuenta.

La grilla usa 100 unidades por celda y mantiene estados free, occupied y blocked. El mapa carga las coordenadas canónicas `(5,3) → (5,19) → (32,19) → (32,5) → (19,5) → (19,32) → (33,32)` y reserva esas celdas para impedir construcción sin bloquear navegación. `GroundPathfinder` calcula cada segmento sobre vecinos ortogonales y permite ensayar una ocupación antes de confirmarla. Flying consume los mismos waypoints ordenados, pero avanza en línea directa e ignora ocupación.

`GamePhaseMachine` inicia en wave 1 / Construction, expone acciones permitidas y emite entradas/salidas observables. Una Construction resuelta inicia Combat; `WaveRuntime` genera enemigos cada segundo, conserva contadores pending/alive/resolved y completa únicamente cuando no quedan pendientes ni vivos.

## Composición con acceso

Login, verificación y restore exitosos convergen en `_start_new_game()` dentro del shell. La sesión sigue en `SessionStore`, mientras cada transición construye un `GameRuntime` limpio. Un restore inválido continúa regresando al landing.

El estado nuevo se inicializa con wave 1, 1000/1000 de vida, score/oro/XP en 0, nivel de jugador 1, progreso 50%, base de 10 enemigos y ninguna support skill. El locale es estado global de aplicación: se conserva al crear la partida, se persiste localmente en `user://preferences.cfg` y la cuenta nace con el idioma seleccionado mediante `POST /auth/register`.

## Verificación

```powershell
godot --headless --path michi-td-game --script res://test/gameplay/m1/run.gd
godot --headless --path michi-td-game --editor --quit
godot --headless --path michi-td-game --export-debug "Windows Desktop" build/michi-td-m1.exe
```

La suite M1 cubre límites y ocupación, conversión mundo/celda, mapa canónico, ruta simple, desvío y bloqueo total, recorrido Flying, eventos de checkpoint/end, transiciones de fase, intervalo de spawn, muerte/escape, completion y aislamiento entre partidas.
