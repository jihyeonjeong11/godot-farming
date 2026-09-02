class_name SaveSlots
extends Control

## 슬롯을 고른 순간. 고른 뒤에 무엇을 할지는 이 화면이 정하지 않는다.
## 새 게임/불러오기/저장 셋이 같은 목록을 함께 쓰기 때문이다.
signal slot_selected(slot: int)

## 닫힐 때 부모 메뉴가 다시 뜨도록 알린다.
signal closed

## 목록 자체는 셋 다 같다. 제목과 "빈 슬롯을 고를 수 있는가"만 다르다.
enum Mode { NEW, LOAD, SAVE }

const TITLES := {
	Mode.NEW: "새 게임",
	Mode.LOAD: "불러오기",
	Mode.SAVE: "저장하기",
}

@onready var title_label: Label = %TitleLabel
@onready var back_button: Button = %BackButton
@onready var slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button, %Slot3Button]

var _mode: Mode = Mode.LOAD


func _ready() -> void:
	visible = false
	back_button.pressed.connect(close)

	# 버튼 순서가 곧 슬롯 번호다. 1부터 세는 이유는 폴더 이름(slot_1)에 그대로 쓰기 때문.
	for i in slot_buttons.size():
		slot_buttons[i].pressed.connect(on_slot_pressed.bind(i + 1))


func open(mode: Mode) -> void:
	_mode = mode
	visible = true
	refresh()
	focus_first_enabled()


## 열 때마다 파일을 다시 읽는다. 저장하고 돌아온 직후에도 목록이 옛 값을 붙들지 않는다.
func refresh() -> void:
	title_label.text = TITLES[_mode]

	for i in slot_buttons.size():
		var slot := i + 1
		var meta: Variant = SaveAndLoad.slot_meta(slot)

		slot_buttons[i].text = "%d.  %s" % [slot, describe(meta)]
		# 불러올 것이 없는 칸은 누를 수 없다. 저장과 새 게임은 빈 칸이 정상이다.
		slot_buttons[i].disabled = _mode == Mode.LOAD and meta == null


## 어느 판인지 가늠하려면 게임 안 날짜와 실제 저장 시각이 둘 다 필요하다.
## 같은 날에 두 슬롯을 저장해두면 일차만으로는 구별되지 않는다.
func describe(meta: Variant) -> String:
	if meta is not Dictionary:
		return "비어 있음"

	return "%d일차  %s  %s" % [
		meta.get("day", 0),
		meta.get("level", "?"),
		short_stamp(String(meta.get("saved_at", ""))),
	]


## "2026-09-02T21:07:33"에서 월-일과 시:분만 남긴다. 연도와 초는 슬롯을 고르는 데 쓰이지 않는다.
func short_stamp(stamp: String) -> String:
	if stamp.length() < 16:
		return ""

	return "%s %s" % [stamp.substr(5, 5), stamp.substr(11, 5)]


## 불러오기에서는 첫 칸이 비어 눌리지 않을 수 있다. 그 칸에 포커스를 두면
## 키보드로 목록을 빠져나갈 수 없다.
func focus_first_enabled() -> void:
	for button in slot_buttons:
		if not button.disabled:
			button.grab_focus()
			return

	back_button.grab_focus()


func on_slot_pressed(slot: int) -> void:
	visible = false
	slot_selected.emit(slot)


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# 슬롯 목록이 열려 있을 때의 ESC는 게임 재개가 아니라 "뒤로가기"로 쓴다.
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		close()
		get_viewport().set_input_as_handled()
