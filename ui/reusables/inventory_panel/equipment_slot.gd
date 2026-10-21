class_name EquipSlot
extends BaseInventorySlot

@export var slot_type: DataTypes.WearSlot = DataTypes.WearSlot.None
@export var index: int
@export var placeholder_texture: Texture2D

@onready var placeholder: TextureRect = $Placeholder


func _ready() -> void:
	placeholder.texture = placeholder_texture


func set_stack(value: ItemStack) -> void:
	super.set_stack(value)
	placeholder.visible = stack == null
