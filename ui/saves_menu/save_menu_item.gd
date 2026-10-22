class_name SaveItem extends Control

signal delete_requested(item: SaveItem)

@onready var player: Player = %Player
@onready var player_container: PanelContainer = $HBoxContainer/PlayerContainer
@onready var item: HBoxContainer = $HBoxContainer
@onready var empty_label: Label = $EmptyLabel
@onready var slot_label: Label = %Slot
@onready var player_name_label: Label = %PlayerName
@onready var money_label: Label = %Money
@onready var elapsed_time_label: Label = %ElapsedTime
@onready var delete_button: ButtonBase = $HBoxContainer/DeleteButton


var slot: int = -1:
	set(value):
		slot = value
		var data := SaveManager.get_load_data(slot)
		if data.is_empty():
			item.hide()
			delete_button.hide()
			empty_label.show()
			return

		item.show()
		delete_button.show()
		empty_label.hide()

		slot_label.text = "Slot %d" % (slot + 1)
		player_name_label.text = str(data.states.game_state.get("player_name", ""))

		var stat: Variant = data.states.game_state.get("player_stat")
		var gold: int = int(stat.get("gold", 0)) if stat is Dictionary else 0
		money_label.text = "%d G" % gold

		var vanity: Variant = data.states.game_state.get("player_vanity")
		#for part in Player.OUTFIT_PARTS.size():
			#player.equip(part, int(vanity[part]) if vanity is Array and part < vanity.size() else -1)

		var seconds: int = int(data.get("seconds_elapsed", 0))
		@warning_ignore("integer_division")
		elapsed_time_label.text = "%02d:%02d" % [seconds / 3600, seconds / 60 % 60]

func _ready() -> void:
	delete_button.pressed.connect(func() -> void: delete_requested.emit(self))
