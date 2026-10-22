extends Control

signal closed()
signal slot_chosen(slot: int, is_empty: bool)
signal delete_answered(confirmed: bool)

@onready var saves_anchor: PanelAnchor = %SavesAnchor
@onready var menu: Menu = %Menu
@onready var confirm_delete_container: ColorRect = %ConfirmDeleteContainer
@onready var confirm_anchor: PanelAnchor = %ConfirmAnchor
@onready var confirm_button: Button = %ConfirmButton
@onready var cancel_button: Button = %CancelButton



func _ready() -> void:
	confirm_anchor.hide()
	confirm_button.pressed.connect(func() -> void: delete_answered.emit(true))
	cancel_button.pressed.connect(func() -> void: delete_answered.emit(false))

	await get_tree().process_frame
	
	refresh_slots()

	menu.call_deferred("focus_first_item")

	saves_anchor.appear()
	
	
func refresh_slots() -> void:
	for i in range(0, menu.get_items().size()):
		var item: SaveItem = menu.get_items()[i]
		item.slot = i
		if not item.mouse_entered.is_connected(_on_slot_mouse_entered):
			item.mouse_entered.connect(_on_slot_mouse_entered.bind(item))
		if not item.gui_input.is_connected(_on_slot_gui_input):
			item.gui_input.connect(_on_slot_gui_input.bind(item))
		if not item.delete_requested.is_connected(_on_slot_delete_requested):
			item.delete_requested.connect(_on_slot_delete_requested)

func _on_saves_menu_actioned(item: Control) -> void :
	slot_chosen.emit(item.slot, SaveManager.get_load_data(item.slot).is_empty())


func close() -> void:
	await saves_anchor.disappear()


func _on_menu_cancelled() -> void:
	await close()
	closed.emit()


func _on_slot_mouse_entered(item: SaveItem) -> void:
	if not menu.is_processing_unhandled_input() or menu.seconds_before_accepting_input > 0:
		return
	if item.focus_mode == Control.FOCUS_NONE or item.has_focus():
		return
	item.grab_focus()


func _on_slot_gui_input(event: InputEvent, item: SaveItem) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	if not menu.is_processing_unhandled_input() or menu.seconds_before_accepting_input > 0:
		return
	item.accept_event()
	item.grab_focus()
	menu.actioned.emit(item)


func _on_slot_delete_requested(item: SaveItem) -> void:
	if not menu.is_processing_unhandled_input() or confirm_delete_container.visible:
		return

	confirm_delete_container.show()
	confirm_anchor.appear()
	cancel_button.grab_focus()

	var confirmed: bool = await delete_answered
	await confirm_anchor.disappear()
	confirm_delete_container.hide()

	if confirmed:
		SaveManager.delete_game(item.slot)
		refresh_slots()
	item.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if confirm_delete_container.visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		delete_answered.emit(false)
