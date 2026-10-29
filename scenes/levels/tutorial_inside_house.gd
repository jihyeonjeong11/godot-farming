extends "res://scenes/levels/base_level.gd"

const FIRST_AID_KIT = preload("uid://kyf60ga4v2nt")


## 약을 얻기 전까지는 들어올 때마다 금고를 가리킨다.
func _enter() -> void:
	if GameState.has_tutorial_flag("obtained_medicine"):
		return

	InventoryManager.updated_inventory.connect(_check_medicine)
	dialogue("safe")


func _check_medicine() -> void:
	if GameState.has_tutorial_flag("obtained_medicine"):
		return
	if InventoryManager.count_item(FIRST_AID_KIT) > 0:
		GameState.set_tutorial_flag("obtained_medicine")
		dialogue("obtained_medicine")
