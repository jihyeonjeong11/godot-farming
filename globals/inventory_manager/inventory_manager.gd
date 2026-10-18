extends Node

# index, 
signal updated_inventory()
signal updated_equipment()
signal consumed()
signal stack_selected()
signal half_stack_selected()

const BASE_INVENTORY_LIMIT = 30
const QUICKBAR_LIMIT = 10

# TODO: 나중에 current_inventory = 10 추가하고 업그레이드할 수 있

func _ready() -> void:
	GameState.inventory.resize(BASE_INVENTORY_LIMIT)

# 아이템 스택 crud
# 스택 이동

func get_stacks() -> void:
	pass
	
func is_inventory_full() -> void:
	pass

func is_stackable() -> void:
	pass

func add_item_stack() -> void:
	pass

func get_item_stack_by_index() -> void:
	pass
	
func delete_stack() -> void:
	pass

func update_stack() -> void:
	pass
