@tool
class_name WorldObject extends Node2D


@export var data: WorldObjectData:
	set(value):
		data = value
		_apply_data()
		
@export var accepted_tools: Array[DataTypes.Tools] = []
@export var persistent := true

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

var state: Dictionary = {}

func _ready() -> void:
	self.add_to_group(&"object")
	if data != null:
		state = default_state()
		if persistent and not Engine.is_editor_hint():
			state = SnapshotActions.populate(self, state)
	_apply_data()

			

func default_state() -> Dictionary:
	return {}

func get_collision_shape() -> CollisionShape2D:
	var shape = get_node_or_null(^"StaticBody2D/CollisionShape2D")
	return shape


func global_collision_rect() -> Rect2:
	var col := get_collision_shape()
	if col == null or col.shape == null:
		return Rect2()
	return col.global_transform * col.shape.get_rect()


func accepts_tool(tool: DataTypes.Tools) -> bool:
	return tool in accepted_tools

func is_deleting() -> bool:
	return is_queued_for_deletion()

func get_drop_item_id() -> StringName:
	return data.item_id if data != null else &""


func on_interact() -> void:
	var item_id := get_drop_item_id()
	if item_id.is_empty():
		return
	var item := ItemDB.get_item(item_id)
	if item == null:
		return
	drop_item(item, 1)
	SnapshotActions.remove(self)
	queue_free()


func drop_item(item: Item, amount: int) -> Node2D:
	var dropped = load("res://items/dropped_item/dropped_item.tscn").instantiate()
	dropped.item = item
	get_parent().add_child(dropped)
	dropped.global_position = global_position
	return dropped


func on_hit(tool: DataTypes.Tools, damage: int) -> void:
	SnapshotActions.remove(self)
	queue_free()


func _apply_data() -> void:
	if not is_node_ready():
		return
	sprite.texture = data.texture if data else null
	
