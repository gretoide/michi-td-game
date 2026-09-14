# Gameplay Foundation

## Responsabilidades

La foundation prepara contratos sin implementar todavía el loop TD. `core/data` carga y valida catálogos; `core/random` ofrece una única fuente de azar; `core/bootstrap` compone ambas dependencias para una partida.

```text
presentation/UI -> orchestration -> gameplay modules -> core contracts
auth/backend -> access shell
gameplay -X-> UI nodes, HTTP, Prisma, MongoDB
```

Los módulos futuros (`grid`, `waves`, `entities`, `combat`, `construction` y `progression`) recibirán `GameplayCatalog` y `RandomSource` por dependencia explícita. No leerán archivos ni crearán RNG locales.

## Datos

Drive contiene la especificación funcional. Los recursos `.tres` versionados en `data/gameplay` son el contrato ejecutable de Godot. Cada catálogo usa IDs estables y se valida antes de habilitar gameplay.

El bootstrap de M0 contiene un registro representativo por tipo. La carga completa de gemas, recetas y waves se integra en M5 sin cambiar los contratos.

## Arranque

`GameplayFoundation.initialize()` carga `res://data/gameplay/catalog.tres`, agrega errores estructurados (`code`, `path`, `message`) y crea el RNG. Una seed explícita de test tiene prioridad; luego se acepta `--seed=<entero>` como argumento de usuario y finalmente se genera una seed aleatoria.

Un catálogo inválido no se reemplaza por defaults silenciosos. La shell de acceso puede seguir mostrando errores, pero ningún módulo de gameplay debe arrancar con datos parciales.

## Testing

Los tests de foundation viven en `test/foundation` y se ejecutan sin plugins mediante:

```powershell
godot --headless --path . --script res://test/foundation/run.gd
```
# Localización

La localización es un servicio de core independiente de gameplay y autenticación. El shell inicial y los módulos futuros consumen claves estables mediante `LocalizationService`; nunca usan el texto traducido como identificador. La preferencia local vive en `user://preferences.cfg` y la API persiste `User.locale` (`en`/`es`) al registrar la cuenta. Si falta una clave en el idioma activo, se utiliza la traducción inglesa.

## M4: enemigos, waves y progresión

`GameRuntime` compone el ciclo `Construction -> Combat -> siguiente wave` con módulos aislados:

```text
WaveDefinition/WaveRuntime -> EnemyRuntime -> CombatRuntime
                                      -> ProgressRuntime
                                      -> EconomyRuntime
                                      -> PlayerProgressionRuntime
                                      -> GameOutcomeRuntime
```

`WaveRuntime` controla conteo y resolución; oro, experiencia, progreso y vida viven en runtimes independientes y se alimentan de eventos de muerte/escape. Victoria o derrota congelan el tick. M4 usa un catálogo bootstrap generado en memoria (50 waves, cadencia de 1 segundo y bosses en 10/20/30/40/50); el dataset completo sigue reservado para M5. `SupportSkillCatalog` expone adquisición y mejora sin overlay visual, que queda para M6.

## Integración de contenido M5

`GameplayDataLoader` mantiene `catalog.tres` como punto de entrada estable y ejecuta `M5ContentCatalog.expand` antes de validar. El expansor materializa el baseline canónico de Drive: 8 gemas básicas con 7 niveles (56 registros), 38 recetas normales + 8 secretas y un perfil/wave para cada una de las 50 waves. Las variantes enemigas posteriores a la primera se conservan fuera del runtime jugable; las abilities excluidas de V1 (`refraction`, `untouchable`, `reactive_armor`, `blink`, `global_slow_aura`) no se activan. Los resultados de recetas se resuelven mediante `GameplayCatalog.gem_definition_for_id`, sin convertir recetas en IDs de gemas básicas ni duplicar el catálogo.

Las abilities se resuelven por capacidades del perfil, no por nombres de waves: `EnemyRuntime`
expone inmunidades, armadura alta, invisibilidad, evasión y aura de desarme, mientras que
Rush/Recharge/ Cleanse actualizan estado temporal, regeneración y umbrales de daño. La
pipeline conserva `damage_type` y `effect_school` separados para que Magic Immunity no
bloquee efectos `NonMagical`. Evasion recibe `RandomSource` por contexto y es reproducible.

`SupportRewardRuntime` genera tres candidatos únicos y reproducibles después de las waves
5, 10, ..., 45. La selección es única y gratuita; al alcanzar cuatro skills distintas sólo
se ofrecen upgrades inferiores a nivel 4. La wave 50 no genera reward y el avance queda
bloqueado hasta resolver el candidato pendiente. El overlay visual continúa en M6.

## M6: UI y experiencia de jugador

`GameplayView` es el único shell visible de gameplay. Lee el estado de `GameRuntime` y
no duplica reglas. `SelectionState` mantiene una selección de gema, piedra o enemigo;
`CommandCardModel` deriva doce acciones estables (`Q W E R / A S D F / Z X C V`) y el
click del botón y su hotkey recorren el mismo handler. El mapa conserva la colocación y
selección por click; el antiguo `ConstructionHarness` queda sólo como herramienta de
pruebas y no se monta en el HUD.

El HUD muestra fase, wave/boss, progress, gold, XP, quality, vida, entidades y feedback.
`SupportRewardRuntime.reward_available` abre un overlay modal de tres candidatos y sólo
la elección por click o `1/2/3` reanuda la wave. Recetas normales se consultan desde el
catálogo (las secretas no se listan) con `P`; configuración se guarda en
`user://game_settings.cfg` y pausa la simulación. Victory/Defeat bloquea el gameplay,
muestra score y permite Restart limpio; `F10` abre el panel Debug sobre los mismos
catálogos y seed del dominio.
