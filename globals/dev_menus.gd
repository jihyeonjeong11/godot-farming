extends CanvasLayer

var activation_code: String = "0129"
var activation_code_so_far: String = ""


## TODO: cheat/dev codes for developer.

var is_active: bool = true

func _ready() -> void :
	if not OS.is_debug_build():
		prints("Disabling OPs in non-debug build.")
		process_mode = ProcessMode.PROCESS_MODE_DISABLED
		return
	dev_fill_inventory()
	dev_shuffle_outfit()

const VANITY_VARIANTS := [3, 2, 3, 2]

func dev_shuffle_outfit() -> void:
	for part in VANITY_VARIANTS.size():
		GameState.player_vanity[part] = randi_range(0, VANITY_VARIANTS[part] - 1)


func dev_fill_inventory() -> void:
	var ids := ItemDB.all_ids()
	ids.shuffle()
	for id in ids.slice(0, 5):
		var item := ItemDB.get_item(id)
		var amount := randi_range(1, ItemStack.slot_capacity(item))
		InventoryActions.obtain(ItemStack.new(item, amount))
	var consumable = ItemDB.dev_get_random_item_by_type(DataTypes.ItemType.Consumable)
	InventoryActions.obtain(ItemStack.new(consumable, 5))
		
func _input(event: InputEvent) -> void :
	if not is_active and event.is_pressed() and not event.is_echo():
		if event is InputEventKey:
			var key: String = event.as_text().to_lower()
			if key == activation_code[activation_code_so_far.length()]:
				activation_code_so_far += key
				if activation_code_so_far == activation_code:
					is_active = true
					activation_code_so_far = ""
		#elif event is InputEventJoypadButton:
			#var button_index: String = str(event.button_index)
			#if button_index == alt_activation_code[activation_code_so_far.length()]:
				#activation_code_so_far += button_index
				#if activation_code_so_far == activation_code:
					#is_active = true
					#activation_code_so_far = ""
