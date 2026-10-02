extends Node

const OBJECT_GROUP := &"object"
const PROPS_GROUP := &"props"
const CROP_INSTANCE := preload("res://scenes/objects/placables/crop_instance.tscn")
const OBJECT_INSTANCE := preload("res://scenes/objects/placables/object_instance.tscn")

var tilemap: TileMapLayer
var tilled_soil_tilemap_layer: TileMapLayer
var watered_soil_layer: WateredSoilLayer
var terrain_set: int = DataTypes.SOIL_TERRAIN_SET
var terrain: int = DataTypes.SoilTerrains.TilledDirt
var player: Player
var objects_layer: Node2D
var crops_layer: Node2D

# TODO: change interaction_range to tile number = 2, not pixel based
@export var interaction_range: float = 88.0
@export var place_ok_tint := Color(0.6, 1.0, 0.6, 0.6)
@export var place_blocked_tint := Color(1.0, 0.45, 0.45, 0.6)
@export var highlight_color := Color(0.3, 0.55, 1.0, 0.4)

var mouse_position: Vector2
var target_position: Vector2
var cell_position: Vector2i
var object_target: ObjectInstance
var props_target: TileMapLayer
var held: Item
var _placeable_cache: Dictionary = {}


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# When Scene swap happend, cursor tilemap and layers terrains
	# 
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
