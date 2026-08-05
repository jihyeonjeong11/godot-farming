extends Node

signal inventory_updated

const BASE_INVENTORY_LIMIT = 30
const QUICKBAR_LIMIT = 10

var inventory = []
var player_node: ApoPlayer

# initial inventory limit size
func _ready():
	inventory.resize(BASE_INVENTORY_LIMIT)

func get_item(i: int):
	if i < 0 or i >= inventory.size():
		return null
	return inventory[i]
	
	
	
func add_item(item: Items) -> bool:
	if item == null:
		return false

	if item.max_stack > 0:
		for i in inventory.size():
			var slot = inventory[i]
			if slot == null:
				continue
			if slot["item"] != item:
				continue
			if slot["amount"] >= item.max_stack:
				continue
			slot["amount"] += 1
			inventory_updated.emit()
			return true

	for i in inventory.size():
		if inventory[i] == null:
			inventory[i] = {"item": item, "amount": 1}
			inventory_updated.emit()
			return true

	return false

func remove_item():
	inventory_updated.emit()
	
func increase_iventory_size():
	inventory_updated.emit()

func set_player_reference(player: ApoPlayer) -> void:
	player_node = player
	
	
