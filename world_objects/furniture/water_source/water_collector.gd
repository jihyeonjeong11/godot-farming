extends WorldObject

const MAX_WATER = SnapshotActions.MAX_WATER
const BOTTLE_WATER := 10

const DRINKING_SOUND = preload("uid://bl3e32fyj134f")
const THIRST = preload("uid://mewgpqlifgrg")
const FILL_SOUND = preload("res://assets/sounds/interactions/watering_can.mp3")


@onready var water_bar: ProgressBar = $WaterBar
@onready var sounds: AudioStreamPlayer2D = $Sounds

func default_state() -> Dictionary:
	return {"water_deposit": MAX_WATER}

func _ready() -> void:
	super()
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
		fill_bottle()

func fill_can(stack: ItemStack) -> void:
	if state["water_deposit"] <= 0:
		SignalBus.toast_requested.emit(THIRST, "No water")
		return
	var amount := mini(stack.item.max_ammo - stack.current_ammo, state["water_deposit"])
	if amount <= 0:
		return
	_play_fill_sound()
	state["water_deposit"] -= amount
	stack.current_ammo += amount
	InventoryManager.updated_inventory.emit()
	_update_bar()

func fill_bottle() -> void:
	if state["water_deposit"] < BOTTLE_WATER:
		SignalBus.toast_requested.emit(THIRST, "No water")
		return
	if not InventoryActions.obtain(ItemStack.new(ItemDB.get_item(&"bottled_water_dirty"), 1)):
		return
	_play_fill_sound()
	state["water_deposit"] -= BOTTLE_WATER
	_update_bar()

func _play_fill_sound() -> void:
	sounds.stream = FILL_SOUND
	sounds.play()

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
