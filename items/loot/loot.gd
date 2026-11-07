class_name LootData
extends Resource

@export var item: Item
@export var amount: int = 1
@export_range(0.0, 1.0, 0.0001) var chance: float = 1.0
