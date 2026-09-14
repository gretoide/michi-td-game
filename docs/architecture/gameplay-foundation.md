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

Las abilities se resuelven por capacidades del perfil, no por nombres de waves: `EnemyRuntime`
expone inmunidades, armadura alta, invisibilidad, evasión y aura de desarme, mientras que
Rush/Recharge/ Cleanse actualizan estado temporal, regeneración y umbrales de daño. La
pipeline conserva `damage_type` y `effect_school` separados para que Magic Immunity no
bloquee efectos `NonMagical`. Evasion recibe `RandomSource` por contexto y es reproducible.

`SupportRewardRuntime` genera tres candidatos únicos y reproducibles después de las waves
5, 10, ..., 45. La selección es única y gratuita; al alcanzar cuatro skills distintas sólo
se ofrecen upgrades inferiores a nivel 4. La wave 50 no genera reward y el avance queda
bloqueado hasta resolver el candidato pendiente. El overlay visual continúa en M6.
