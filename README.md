# Michi TD Game

Cliente de escritorio Godot 4.7.2 para Michi TD. Esta primera base permite registrarse o iniciar sesión sobre un carrusel de paisajes, con un panel de acceso adaptable y estilo medieval.

El juego usa una base de 1920×1080, arranca en una ventana de 1280×720 y escala el contenido para conservar la composición en resoluciones distintas. El acceso usa un panel translúcido con desenfoque de fondo y permite mostrar u ocultar la contraseña.

El carrusel alterna sus ilustraciones cada 8 segundos con un crossfade suave. Los recursos runtime están organizados en `assets/art`, `assets/audio`, `assets/fonts` y `assets/ui`; la información de licencia está en `assets/licenses`.

## Desarrollo

- Requiere Godot 4.7.2 estándar para Windows y la API ejecutándose en `http://127.0.0.1:3000`.
- La URL de autenticación puede cambiarse con `MICHI_API_URL`; debe incluir el prefijo `/api/v1`.
- Ejecutar desde esta carpeta: `godot --path .`

La foundation de gameplay usa catálogos tipados `.tres` en `data/gameplay`. Para validar sus contratos y el RNG determinista:

```powershell
godot --headless --path . --script res://test/foundation/run.gd
godot --headless --path . --script res://test/gameplay/m1/run.gd
godot --headless --path . --script res://test/gameplay/m2/run.gd
godot --headless --path . --script res://test/gameplay/m3/run.gd
godot --headless --path . --script res://test/gameplay/m4/run.gd
godot --headless --path . --script res://test/gameplay/m5/run.gd
godot --headless --path . --script res://test/gameplay/m6/run.gd
godot --headless --path . --script res://test/gameplay/m7/run.gd
```

## Validar y exportar

```powershell
godot --headless --path . --editor --quit
godot --headless --path . --quit-after 2
godot --headless --path . --export-debug "Windows Desktop" build/michi-td.exe
```

La guía de arquitectura y la matriz de regresión están en `docs/README.md`.

El access token se mantiene únicamente en memoria. Para reconocer al usuario al reabrir el juego se guarda solo el refresh token opaco en `user://session.cfg`; al cerrar sesión se revoca y se elimina. El idioma se guarda por separado en `user://preferences.cfg` y se conserva al crear una partida nueva.

Los prototipos visuales de la partida usan el Fields tileset de CraftPix (licencia indicada en `assets`), gemas como unidades defensivas, proyectiles Pixel Fireball Pack de growmaster, personajes Tiny RPG Soldier/Orc (licencia del pack) y elementos de interfaz Pixel UI de Kenney (CC0). Se mantuvieron los PNG originales pixel-perfect.
