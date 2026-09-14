# Matriz de regresión FR V1

| Área | Evidencia |
|---|---|
| Foundation y datos | `test/foundation/run.gd` |
| Core TD Loop | `test/gameplay/m1/run.gd` |
| Gems y Construction | `test/gameplay/m2/run.gd` |
| Combate y efectos | `test/gameplay/m3/run.gd` |
| Enemigos, waves y progresión | `test/gameplay/m4/run.gd` |
| Dataset V1 | `test/gameplay/m5/run.gd` |
| HUD, rewards y localización | `test/gameplay/m6/run.gd` |
| Integración y release | `test/gameplay/m7/run.gd` |

La matriz no reemplaza smoke de servicios externos de autenticación. El smoke
M7 valida dos recorridos deterministas con seed `424242` y registra como deuda
los warnings de recursos vivos de Godot al cerrar headless.
