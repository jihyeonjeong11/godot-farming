class_name InventorySlot
extends Button

## 이 칸을 우클릭했을 때. Button.pressed는 좌클릭만 잡아서 따로 둔다.
signal right_pressed

@export var selected_item: Items

## 배열에서 이 칸이 가리키는 위치. 부모가 생성할 때 넣어준다.
var slot_index: int = -1

## 이 칸이 보고 있는 배열. 부모가 만들 때 넣어준다.
## 퀵바·인벤토리 창은 Inventory.inventory를, 상자 격자는 상자의 칸을 넣는다.
## 이 한 줄 덕분에 같은 칸 씬이 세 군데에 그대로 쓰인다.
##
## 게터로 Inventory를 기본값 삼지 않는다. 클래스 본문에서 오토로드를 건드리면
## 타입 해석이 꼬여 스크립트 전체가 컴파일에 실패한다.
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


func _show_ammo(item: Items) -> void:
	if item.max_ammo <= 0:
		ammo_bar.hide()
		return

	ammo_bar.max_value = item.max_ammo
	ammo_bar.value = clampi(item.current_ammo, 0, item.max_ammo)
	ammo_bar.show()
