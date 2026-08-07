class_name CropsCursorComponent
extends Node


@export var tilled_soil_tilemap_layer: TileMapLayer

@onready var player: ApoPlayer = get_tree().get_first_node_in_group("player")

var mouse_position: Vector2
var cell_position: Vector2i
var cell_source_id: int
var local_cell_position: Vector2
var distance: float

var potato_plant_scene = preload("res://scenes/objects/crops/potato/potato.tscn")
var wheat_plant_scene = preload("res://scenes/objects/crops/wheat/wheat.tscn")
 
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SignalBus.tool_used.connect(_on_tool_used)

func _on_tool_used(item: Items, _user_position: Vector2, _target_position: Vector2) -> void:
	# and selected tool is tool
	if item.tool_type != null && item.tool_type == ApoDataTypes.Tools.PlantPotato:
		get_cell_under_mouse()
		add_crop()
	elif item.tool_type != null && item.tool_type == ApoDataTypes.Tools.MineRock:
		get_cell_under_mouse()
		remove_crop()
	

func get_cell_under_mouse() -> void:
	mouse_position = tilled_soil_tilemap_layer.get_local_mouse_position()
	cell_position = tilled_soil_tilemap_layer.local_to_map(mouse_position)
	cell_source_id = tilled_soil_tilemap_layer.get_cell_source_id(cell_position)
	local_cell_position = tilled_soil_tilemap_layer.map_to_local(cell_position)
	distance = player.global_position.distance_to(local_cell_position)
	

func add_crop() -> void:
	# TilledSoil 레이어에 타일이 없으면(-1) 안 갈린 맨땅이라 심을 수 없다.
	if distance < 20.0 && cell_source_id != -1:
		var potato_instance = potato_plant_scene.instantiate() as Node2D
		potato_instance.global_position = local_cell_position
		get_parent().find_child("CropFields").add_child(potato_instance)
	
func remove_crop() -> void:
	if distance < 20.0:
		var crop_nodes = get_parent().find_child("CropFields").get_children()
		for node: Node2D in crop_nodes:
			if node.global_position == local_cell_position:
				node.queue_free()
