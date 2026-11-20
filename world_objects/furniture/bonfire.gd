@tool
extends WorldObject

const FIRE_ON = preload("uid://cluwpcp6k6vrc")
const FIRE_OFF = preload("uid://by72sp3vkhet8")

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sounds: AudioStreamPlayer2D = $Sounds

func default_state() -> Dictionary:
	return {"is_on": true}

func _ready() -> void:
	super()
	_apply_lit()
	if not Engine.is_editor_hint():
		TimeManager.day_passed.connect(_on_day_passed)

func _on_day_passed(_day: int) -> void:
	_apply_lit()

func on_interact() -> void:
	if state.is_on:
		SignalBus.crafting_opened.emit(DataTypes.RecipeType.Cooking)
		return
	if not state.is_on:
		if not InventoryManager.remove_item(ItemDB.get_item(&"log"), 3):
			SignalBus.toast_requested.emit(ItemDB.get_item(&"log").item_texture, "Need 3 logs to fire")
			return
		state.is_on = not state.is_on
		sounds.stream = FIRE_ON if state.is_on else FIRE_OFF
		sounds.play()
		_apply_lit()

func _apply_lit() -> void:
	anim.play(&"on" if state.is_on else &"off")
	
