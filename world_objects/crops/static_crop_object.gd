@tool
class_name StaticCropObject extends CropObject


func _ready() -> void:
	if data != null:
		state["growth_stage"] = data.max_growth_stage
	super()


func populate() -> void:
	pass


func on_day_passed(_day: int) -> void:
	pass


func on_interact() -> void:
	play_shake()
	if data == null:
		return
	if not data.loot_pool.is_empty():
		SoundManager.play_sound(preload("uid://dtkma6bmtb12v"))
	for entry in data.loot_pool:
		if randf() < entry.chance:
			InventoryActions.obtain(ItemStack.new(entry.item, entry.amount))
	queue_free()
