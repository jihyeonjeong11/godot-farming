class_name InventorySlot
extends Button

## 이 칸을 우클릭했을 때. Button.pressed는 좌클릭만 잡아서 따로 둔다.
signal right_pressed

@export var selected_item: Item

## 배열에서 이 칸이 가리키는 위치. 부모가 생성할 때 넣어준다.
var slot_index: int = -1

var source: Array = []

var draggable: bool = true

var price_label: String = "가치"

@onready var amount_label: Label = $AmountLabel
@onready var ammo_bar: ProgressBar = $AmmoBar


func _ready() -> void:
	clear()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_RIGHT \
			and event.pressed:
		accept_event()
		right_pressed.emit()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not draggable or selected_item == null or slot_index < 0:
		return null

	# 드래그하는 동안 마우스를 따라다닐 미리보기.
	var preview := TextureRect.new()
	preview.texture = selected_item.item_texture
	preview.custom_minimum_size = size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.modulate.a = 0.8
	set_drag_preview(preview)

	return {"from_index": slot_index, "from_source": source}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return draggable and slot_index >= 0 and data is Dictionary and data.has("from_source")


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var from_source: Array = data["from_source"]
	var from_index: int = data["from_index"]
	var to_source: Array = source

	if from_index < 0 or from_index >= from_source.size():
		return
	if slot_index < 0 or slot_index >= to_source.size():
		return
	if is_same(from_source, to_source) and from_index == slot_index:
		return

	var moved: ItemStack = from_source[from_index]
	from_source[from_index] = to_source[slot_index]
	to_source[slot_index] = moved

	# 양쪽 격자를 한 신호로 다시 그린다. 상자 UI도 이걸 듣는다.
	Inventory.inventory_updated.emit()

	# 입든 벗든 배열 하나가 장비 칸이면 장비가 바뀐 것이다. 벗을 때는 이 _drop_data가
	# 인벤토리 칸 쪽에서 도므로, EquipmentSlot 에만 걸어두면 벗기를 놓친다.
	if Inventory.is_equipment_source(from_source) or Inventory.is_equipment_source(to_source):
		Inventory.equipment_updated.emit()


func set_slot(stack: ItemStack) -> void:
	if stack == null or stack.item == null:
		clear()
		return

	var item := stack.item
	selected_item = item
	icon = item.item_texture
	tooltip_text = item.describe(price_label)

	amount_label.text = str(stack.amount)
	amount_label.visible = stack.amount > 1

	_show_ammo(item)


func clear() -> void:
	selected_item = null
	icon = null
	tooltip_text = ""
	amount_label.hide()
	ammo_bar.hide()


func _show_ammo(item: Item) -> void:
	if item.max_ammo <= 0:
		ammo_bar.hide()
		return

	ammo_bar.max_value = item.max_ammo
	ammo_bar.value = clampi(item.current_ammo, 0, item.max_ammo)
	ammo_bar.show()
