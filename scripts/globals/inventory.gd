extends Node

signal inventory_updated

const BASE_INVENTORY_LIMIT = 30

var inventory = []
var player_node: ApoPlayer

# initial inventory limit size
func _ready():
	inventory.resize(BASE_INVENTORY_LIMIT)
	
func add_item():
	inventory_updated.emit()
	
func remove_item():
	inventory_updated.emit()
	
func increase_iventory_size():
	inventory_updated.emit()

func set_player_reference(player: ApoPlayer) -> void:
	player_node = player
