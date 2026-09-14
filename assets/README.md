# Organización de assets

- `art/backgrounds/`: fondos de escenas.
- `art/branding/`: identidad y logo.
- `art/gameplay/`: arte usado durante la partida, separado en `environment/`,
  `terrain/`, `building/`, `hud/`, `markers/`, `projectiles/`, `towers/`, `enemies/` y
  `gems/<color>/`. `terrain/fields/` contiene los tiles del suelo; los objetos
  de vegetación, props y landmarks viven bajo `environment/`. Las gemas se
  guardan por color y cada archivo conserva su nivel y frame. Los proyectiles
  animados se guardan en su hoja original bajo `projectiles/`. La decoración
  del mapa usa las variantes del mismo Fields tileset (pastos, flores,
  arbustos, tierra, troncos, cajas, lámparas, árboles y cercos).
- `audio/`: música y efectos, separados por función.
- `fonts/`: tipografías del juego.
- `ui/buttons/`, `ui/panels/`, `ui/icons/`, `ui/cursors/`: componentes visuales
  de interfaz.
- Los archivos `.import` son metadatos generados por Godot y no se gestionan
  con Git LFS.

Los binarios de `assets/` se almacenan con Git LFS según `.gitattributes`.
