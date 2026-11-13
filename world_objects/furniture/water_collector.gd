extends WorldObject

const MAX_WATER = SnapshotActions.MAX_WATER

const DRINKING_SOUND = preload("uid://bl3e32fyj134f")
const THIRST = preload("uid://mewgpqlifgrg")
const FILL_SOUND = preload("res://assets/sounds/interactions/watering_can.mp3")


@onready var water_bar: ProgressBar = $WaterBar

var state = {
	"water_deposit": 30
}

func _ready() -> void:
	super()
	state = SnapshotActions.populate(global_position, data.id, state)
	TimeManager.day_passed.connect(_on_advance_day)
	water_bar.max_value = MAX_WATER
	_update_bar()

func _update_bar() -> void:
	water_bar.value = state["water_deposit"]

func on_interact() -> void:
	var stack := InventoryManager.get_item_stack_by_index(GameState.selected_slot)
	if stack != null and stack.item != null and stack.item.tool_type == DataTypes.Tools.WaterCrops:
		fill_can(stack)
	else:
		drink()

func fill_can(stack: ItemStack) -> void:
	if state["water_deposit"] <= 0:
		SignalBus.toast_requested.emit(THIRST, "No water")
		return
	var amount := mini(stack.item.max_ammo - stack.current_ammo, state["water_deposit"])
	if amount <= 0:
		return
	SoundManager.play_sound(FILL_SOUND)
	state["water_deposit"] -= amount
	stack.current_ammo += amount
	InventoryManager.updated_inventory.emit()
	_update_bar()

func _on_advance_day(_day: int) -> void:
	_update_bar()

func drink() -> void:
	if state["water_deposit"] > 0:
		var missing := GameState.player_stat.current_max_stamina - GameState.player_stat.stamina
		var amount := mini(10, mini(missing, state["water_deposit"]))
		if amount <= 0:
			return
		SoundManager.play_sound(DRINKING_SOUND)
		state["water_deposit"] -= amount
		StatActions.change_stamina(amount)
		_update_bar()
	else:
		SignalBus.toast_requested.emit(THIRST, "No water")
