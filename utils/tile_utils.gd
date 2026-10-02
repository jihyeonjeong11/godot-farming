class_name TileUtils
extends RefCounted

const GROUND_LAYERS: Array[String] = [
	"Road", "ConcretePath", "StonePath", "Walk", "Floors", "Land",
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
