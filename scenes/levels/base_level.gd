class_name Base_level extends Node2D

@onready var camera_component: Camera = $CameraComponent

@export var camera_zoom: Vector2 = Vector2(3, 3)

@export var dialogue_resource: DialogueResource
@export var level_key: DataTypes.Levels
@export var camera_land_inset := 1
const UI_MANAGER = preload("uid://bqrbyohvqh031")
const FARM_SCENE_PATH := "res://scenes/test_scenes/farm/farm_latest.tscn"

var interface: CanvasLayer

@onready var dev_info: CanvasLayer = $DevInfo
@onready var target_label: Label = $DevInfo/TargetLabel

func _ready() -> void :
	camera_component.zoom = camera_zoom
	limit_camera_to_land()
	#SessionState.cinematic_stack_size = 0

	interface = UI_MANAGER.instantiate()
	add_child(interface)
	dev_info.visible = OS.is_debug_build()
	if dev_info.visible:
		get_tree().process_frame.connect(update_dev_info)
#
	#if not has_interface:
		#interface.hud.hide()
	restore_snapshot_tiles
	restore_snapshot_objects()
	_enter()

func _enter() -> void:
	pass

func restore_snapshot_tiles() -> void:
	pass

func restore_snapshot_objects() -> void:
	if get_tree().current_scene.scene_file_path != FARM_SCENE_PATH:
		return
	var occupied := {}
	for node in get_tree().get_nodes_in_group(&"object"):
		if node is not NatureSpawner:
			occupied[SnapshotActions.get_cell_from_pos(node.global_position)] = true
	for cell: Vector2i in GameState.farm_snapshot:
		var id: String = GameState.farm_snapshot[cell].get("id", "")
		if id.is_empty() or occupied.has(cell):
			continue
		var object := WorldObjectDB.create(id)
		if object == null:
			continue
		object.position = SnapshotActions.get_pos_from_cell(cell)
		add_child(object)

func limit_camera_to_land() -> void:
	var land := get_node_or_null(^"Tilemap/Land") as TileMapLayer
	if land == null:
		land = get_node_or_null(^"Tilemap/Back") as TileMapLayer
	if land == null or land.tile_set == null:
		return
	var used := land.get_used_rect().grow(-camera_land_inset)
	if used.size.x <= 0 or used.size.y <= 0:
		return
	var half := Vector2(land.tile_set.tile_size) / 2.0
	var top_left := land.to_global(land.map_to_local(used.position) - half)
	var bottom_right := land.to_global(land.map_to_local(used.end) - half)
	camera_component.limit_left = floori(top_left.x)
	camera_component.limit_top = floori(top_left.y)
	camera_component.limit_right = ceili(bottom_right.x)
	camera_component.limit_bottom = ceili(bottom_right.y)

func update_dev_info() -> void:
	var layers: Array = SessionState.target_dict["layers"]
	var layers_text: String = ", ".join(PackedStringArray(layers)) if not layers.is_empty() else "-"
	var tile = SessionState.target_dict["tile"]
	var terrain: String = SessionState.target_dict["terrain"]
	var target_object = SessionState.target_dict["object"]
	var object_name: String = String(target_object.data.name) if is_instance_valid(target_object) else "-"
	var target_building = SessionState.target_dict["building"]
	var building_name: String = target_building.name if is_instance_valid(target_building) else "-"
	var door_name: String = "yes" if CursorActions.is_at_door() else "-"
	target_label.text = "layers: %s\ntile: %s\nterrain: %s\nobject: %s\nbuilding: %s\ndoor: %s" % [layers_text, tile if tile else "-", terrain if terrain else "-", object_name, building_name, door_name]

func dialogue(key: String) -> void :
	SignalBus.request_dialogue(dialogue_resource, key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_READY:
		move_child(get_node(^"Player"), -1)
