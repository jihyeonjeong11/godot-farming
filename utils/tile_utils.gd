class_name TileUtils
extends RefCounted

# Tile 변환 관련 utils

const TILLABLE_TERRAINS: Array[String] = ["Dirt", "Dark Dirt", "Red_Dirt"]


const GROUND_LAYERS: Array[String] = [
	"Road", "ConcretePath", "StonePath", "Walk", "Floors", "Land", "Back",
]



static func ground_layers(level: Node) -> Array[TileMapLayer]:
	var layers: Array[TileMapLayer] = []
	var tilemap := level.get_node_or_null("Tilemap") if level != null else null
	if tilemap == null:
		return layers
	for layer_name in GROUND_LAYERS:
		var layer := tilemap.get_node_or_null(layer_name) as TileMapLayer
		if layer != null and layer.tile_set != null:
			layers.append(layer)
	return layers


static func terrain_at(layers: Array[TileMapLayer], global_pos: Vector2) -> String:
	for layer in layers:
		var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(global_pos)))
		if data == null or data.terrain < 0:
			continue
		return layer.tile_set.get_terrain_name(data.terrain_set, data.terrain)
	return ""



static func is_covered(level: Node, global_pos: Vector2, base_name: StringName) -> bool:
	var tilemap := level.get_node_or_null(^"Tilemap") if level != null else null
	if tilemap == null:
		return false
	for child in tilemap.get_children():
		var layer := child as TileMapLayer
		if layer == null or layer.name == base_name:
			continue
		if layer.get_cell_source_id(layer.local_to_map(layer.to_local(global_pos))) != -1:
			return true
	return false


static func is_tillable(level: Node, global_pos: Vector2) -> bool:
	var back := level.get_node_or_null(^"Tilemap/Back") as TileMapLayer if level != null else null
	if back == null:
		return false
	var layers: Array[TileMapLayer] = [back]
	if not (terrain_at(layers, global_pos) in TILLABLE_TERRAINS):
		return false
	return not is_covered(level, global_pos, &"Back")
	
