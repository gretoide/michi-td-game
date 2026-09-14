# Release candidate M7

## Comandos

Desde `michi-td`:

```powershell
$godot = '.\godot\Godot_v4.7.2-stable_win64_console.exe'
& $godot --headless --path michi-td-game --script res://test/gameplay/m7/run.gd
& $godot --headless --path michi-td-game --editor --quit
& $godot --headless --path michi-td-game --export-debug 'Windows Desktop' build/michi-td-m7.exe
```

La prueba integrada usa la seed `424242`, valida dos recorridos idénticos,
resolución de waves 1–50, recompensas, economía, XP, vida y victoria.

## Criterio de aceptación

- el playthrough determinista termina en `victory`;
- la firma terminal se repite con la misma seed;
- los runners de foundation y M1–M6 siguen pasando;
- el editor y el export Windows terminan correctamente;
- la API continúa pasando sus suites de unit, e2e y build.

## Limitaciones conocidas

El catálogo visual y de gameplay continúa usando fixtures/bootstrap donde así
lo define M5. Los runners headless pueden mostrar warnings de `ObjectDB` y
recursos vivos al salir; deben limpiarse en una iteración posterior de
estabilidad, pero no son errores de aserción ni impiden el release candidate.
