@icon("./vertical_menu.svg")

class_name VerticalMenu extends VBoxContainer


signal focused(item: Control)
signal selection_changed(item: Control)
signal actioned(item: Control)
signal cancelled()
signal unknown_input(event: InputEvent)


@export var pointer: Node
@export var pointer_valign: float = 0.4
@export var pointer_halign: float = -5
@export var use_manual_focus: bool = false
@export var auto_focus_first_item: bool = false
@export var cancel_item: Control

var last_focused_item: Control = null
var is_locked: bool = false
var seconds_before_accepting_input: float = 0


func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)

	if not use_manual_focus:
		configure_focus()

	if auto_focus_first_item:
		focus_first_item()


func _unhandled_input(event):
	if not is_visible_in_tree(): return

	var item = get_focused_item()
	if item:
		get_viewport().set_input_as_handled()

		if seconds_before_accepting_input > 0: return

		if event.is_action_pressed(&"ui_accept"):
			actioned.emit(item)
		elif event.is_action_pressed(&"ui_cancel"):
			if is_instance_valid(cancel_item):
				actioned.emit(cancel_item)
			else:
				cancelled.emit()
		else:
			unknown_input.emit(event)


func _process(delta):
	update_selection()

	if seconds_before_accepting_input > 0:
		seconds_before_accepting_input -= delta





func lock() -> void :
	set_process_unhandled_input(false)
	var item = get_focused_item()
	if item:
		item.focus_mode = Control.FOCUS_NONE


func unlock() -> void :
	set_process_unhandled_input(true)
	var item = get_focused_item()
	if item:
		item.focus_mode = Control.FOCUS_ALL


func get_focused_item() -> Control:
	var item = get_viewport().gui_get_focus_owner()
	return item if item in get_children() else null


func get_items() -> Array[Control]:
	var items: Array[Control] = []
	for child in get_children():
		if not child is Control: continue
		if "Heading" in child.name: continue
		if "Divider" in child.name: continue
		if "Spacer" in child.name: continue
		if not child.visible: continue
		if child is HSeparator or child is VSeparator: continue
		if child.has_meta("disallowed"): continue
		if child.is_queued_for_deletion(): continue

		items.append(child)

	return items


func focus_first_item() -> void :
	var item = get_items()[0]
	item.grab_focus()
	_on_focus_changed(item)
	seconds_before_accepting_input = 0.3


func focus_last_focused_item() -> void :
	last_focused_item.grab_focus()
	_on_focus_changed(last_focused_item)
	seconds_before_accepting_input = 0.3


func configure_focus() -> void :
	var items = get_items()
	for i in items.size():
		var item: Control = items[i]

		item.focus_mode = Control.FOCUS_ALL

		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()

		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()

		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items[i + 1].get_path()
			item.focus_next = items[i + 1].get_path()


func update_selection() -> void :
	var item = get_focused_item()

	if not item:
		item = last_focused_item

	if is_instance_valid(item) and is_instance_valid(pointer) and visible:
		var vertial_offset: float = 0
		if pointer_valign > 0 and pointer_valign < 1:
			vertial_offset = item.size.y * pointer_valign
		else:
			vertial_offset = pointer_valign

		var horizontal_offset: float = 0
		if pointer_halign > 0 and pointer_halign < 1:
			horizontal_offset = item.size.x * pointer_halign
		else:
			horizontal_offset += pointer_halign

		pointer.global_position = Vector2(global_position.x + horizontal_offset, item.global_position.y + vertial_offset)







func _on_focus_changed(item: Control) -> void :
	if not item: return
	if not item in get_children(): return


	if is_instance_valid(last_focused_item) and last_focused_item.get_index() != item.get_index():
		selection_changed.emit(item)

	focused.emit(item)

	last_focused_item = item

	update_selection()


func _on_menu_visibility_changed() -> void :
	if is_instance_valid(pointer):
		pointer.visible = visible
