# M7 — Integración y release

M7 valida el circuito completo de V1 sobre los contratos de M0–M6, sin agregar
endpoints ni persistencia de gameplay.

## Playthrough determinista

`test/gameplay/m7/playthrough.gd` crea una partida limpia con seed `424242`,
completa Construction, ejecuta Combat y resuelve las 50 waves. El runner repite
el circuito con la misma seed y compara la firma terminal y la longitud del
log. Las recompensas de las waves 5–45 se eligen de forma determinista.

El test también cubre el caso de cuatro support skills ocupadas: no se ofrecen
skills nuevas que el catálogo ya no puede adquirir.

## Matriz de regresión

Los runners de `test/foundation`, `test/gameplay/m1` … `m6` conservan las
pruebas específicas de cada milestone. `m7/run.gd` funciona como smoke
integrado y no reemplaza esa cobertura.

## Release y estabilidad

La validación de release usa Godot 4.7.2 en modo headless, editor y export
Windows Desktop. El binario generado es `build/michi-td-m7.exe` (artefacto
local ignorado por Git). La API se valida por separado con `npm test`,
`npm run test:e2e` y `npm run build`.

Godot puede informar instancias `ObjectDB` o recursos aún referenciados al
cerrar los runners headless. Se registran como deuda de limpieza del harness;
no alteran el código productivo ni el resultado de las aserciones.
