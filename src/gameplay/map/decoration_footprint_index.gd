class_name DecorationFootprintIndex
extends RefCounted

## Runtime/editor bridge that treats authored decoration tiles as visual
## assets instead of independent gameplay cells. It deliberately excludes the
## fence layer and never contributes obstacles to the logical grid.
const CELL_SIZE := 16.0
const DEFAULT_TILE_SIZE := Vector2i(16, 16)

var groups: Array[Dictionary] = []

func rebuild(decorations: Node) -> void:
	groups.clear()
	if decorations == null:
		return
	var layers: Array[TileMapLayer] = []
	for layer_name in ["DecorationTiles", "DecorationForeground"]:
		var layer := decorations.get_node_or_null(layer_name) as TileMapLayer
		if layer != null:
			layers.append(layer)

	# Large atlas tiles and scene tiles are already complete assets. Normal
	# 16x16 atlas tiles are grouped by connected source regions below.
	var regular_cells: Dictionary = {}
	for layer in layers:
		for cell: Vector2i in layer.get_used_cells():
			var source_id := layer.get_cell_source_id(cell)
			if source_id < 0:
				continue
			var source := layer.tile_set.get_source(source_id)
			var bounds := _tile_visual_rect(layer, cell, source_id, source)
			if bool(bounds.get("complete_asset", false)):
				groups.append({
					"source_id": source_id,
					"bounds": bounds["rect"],
					"entries": [{"layer": layer, "cell": cell}],
				})
			else:
				var key := "%s:%s" % [source_id, layer.get_instance_id()]
				if not regular_cells.has(key):
					regular_cells[key] = {"source_id": source_id, "layer": layer, "cells": []}
				regular_cells[key]["cells"].append(cell)

	for key in regular_cells.keys():
		var bucket: Dictionary = regular_cells[key]
		var pending: Dictionary = {}
		for cell: Vector2i in bucket["cells"]:
			pending[cell] = true
		while not pending.is_empty():
			var first: Vector2i = pending.keys()[0]
			var component: Array[Vector2i] = []
			var queue: Array[Vector2i] = [first]
			pending.erase(first)
			while not queue.is_empty():
				var current: Vector2i = queue.pop_front()
				component.append(current)
				for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
					var neighbor: Vector2i = current + direction
					if pending.has(neighbor):
						pending.erase(neighbor)
						queue.append(neighbor)
			var rect := Rect2(Vector2(component[0]) * CELL_SIZE, Vector2.ONE * CELL_SIZE)
			for cell in component:
				rect = rect.merge(Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE))
			var entries: Array[Dictionary] = []
			for cell in component:
				entries.append({"layer": bucket["layer"], "cell": cell})
			groups.append({"source_id": bucket["source_id"], "bounds": rect, "entries": entries})

	# Explicit object scenes are authoritative over their complete footprint.
	# Accept direct children as well for older authored maps that placed
	# MapDecorationMarker nodes directly under Decorations.
	_collect_object_groups(decorations)

func _collect_object_groups(node: Node) -> void:
	for child in node.get_children():
		if child is MapDecorationObject:
			var object := child as MapDecorationObject
			var footprint := object.authored_footprint()
			groups.append({
				"source_id": -1,
				"bounds": Rect2(Vector2(footprint.position) * CELL_SIZE, Vector2(footprint.size) * CELL_SIZE),
				"entries": [{"object": object}],
			})
		elif child is Node2D and not child is TileMapLayer:
			_collect_object_groups(child)

func groups_intersecting(authored_rect: Rect2) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for group: Dictionary in groups:
		if (group["bounds"] as Rect2).intersects(authored_rect):
			result.append(group)
	return result

func groups_for_placement(authored_rect: Rect2) -> Array[Dictionary]:
	var candidates := groups_intersecting(authored_rect)
	if candidates.size() <= 1:
		return candidates
	var center := authored_rect.get_center()
	var containing: Array[Dictionary] = []
	for group: Dictionary in candidates:
		if (group["bounds"] as Rect2).has_point(center):
			containing.append(group)
	if containing.size() == 1:
		return containing
	if containing.size() > 1:
		# A large authored prop can overlap a small neighboring tile because
		# the runtime grid is coarser. Keep the dominant visual asset only.
		var dominant: Dictionary = containing[0]
		var dominant_area := (dominant["bounds"] as Rect2).get_area()
		for index in range(1, containing.size()):
			var candidate: Dictionary = containing[index]
			var candidate_area := (candidate["bounds"] as Rect2).get_area()
			if candidate_area > dominant_area:
				dominant = candidate
				dominant_area = candidate_area
		return [dominant]
	return candidates

func erase_group(group: Dictionary) -> void:
	for entry: Dictionary in group.get("entries", []):
		if entry.has("object"):
			var object := entry["object"] as Node
			if is_instance_valid(object):
				object.queue_free()
			continue
		var layer := entry.get("layer") as TileMapLayer
		if is_instance_valid(layer):
			layer.erase_cell(entry["cell"])

func _tile_visual_rect(layer: TileMapLayer, cell: Vector2i, source_id: int, source: TileSetSource) -> Dictionary:
	var scene_source := source as TileSetScenesCollectionSource
	if scene_source != null:
		var scene_id := layer.get_cell_atlas_coords(cell).x
		var scene := scene_source.get_scene_tile_scene(scene_id) if scene_id >= 0 else null
		var scene_size := _scene_visual_size(scene)
		var center := (Vector2(cell) + Vector2.ONE * 0.5) * CELL_SIZE
		return {"complete_asset": true, "rect": Rect2(center - scene_size * 0.5, scene_size)}

	var atlas_source := source as TileSetAtlasSource
	if atlas_source == null:
		return {"complete_asset": false, "rect": Rect2(Vector2(cell) * CELL_SIZE, Vector2.ONE * CELL_SIZE)}
	var region := atlas_source.get_texture_region_size()
	var size := Vector2(region)
	var tile_data := layer.get_cell_tile_data(cell)
	var origin := Vector2.ZERO
	if tile_data != null:
		origin = Vector2(tile_data.texture_origin)
	var center := (Vector2(cell) + Vector2.ONE * 0.5) * CELL_SIZE + origin
	return {
		"complete_asset": region != DEFAULT_TILE_SIZE,
		"rect": Rect2(center - size * 0.5, size),
	}

func _scene_visual_size(scene: PackedScene) -> Vector2:
	if scene == null:
		return Vector2.ONE * CELL_SIZE
	var instance := scene.instantiate()
	var bounds := Rect2(Vector2.ZERO, Vector2.ZERO)
	var found := false
	var sprites: Array[Node] = []
	_collect_visual_nodes(instance, sprites)
	for node: Node in sprites:
		var sprite := node as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var size := sprite.texture.get_size() * sprite.scale.abs()
		var rect := Rect2(sprite.position - size * 0.5, size)
		if not found:
			bounds = rect
			found = true
		else:
			bounds = bounds.merge(rect)
	instance.free()
	return bounds.size if found else Vector2.ONE * CELL_SIZE

func _collect_visual_nodes(node: Node, result: Array[Node]) -> void:
	if node is Sprite2D:
		result.append(node)
	for child in node.get_children():
		_collect_visual_nodes(child, result)
