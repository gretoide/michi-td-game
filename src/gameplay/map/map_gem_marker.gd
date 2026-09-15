@tool
class_name MapGemMarker
extends MapEditableSprite

## Authored gem markers are map content, not round-generated GemInstances.
## They are therefore safe to move/remove without changing round generation.
@export var gem_id := "ruby"
@export_range(1, 50, 1) var level := 1

