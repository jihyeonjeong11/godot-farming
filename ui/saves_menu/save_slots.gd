class_name SaveSlots
extends Control
#
#signal slot_selected(slot: int)
#
#signal closed
#
#enum Mode { NEW, LOAD, SAVE }
#
#const TITLES := {
	#Mode.NEW: "새 게임",
	#Mode.LOAD: "불러오기",
	#Mode.SAVE: "저장하기",
#}
#
#@onready var title_label: Label = %TitleLabel
#@onready var back_button: Button = %BackButton
#@onready var slot_buttons: Array[Button] = [%Slot1Button, %Slot2Button, %Slot3Button]
#@onready var delete_buttons: Array[Button] = [%Slot1Delete, %Slot2Delete, %Slot3Delete]
#
#var _mode: Mode = Mode.LOAD
#
#
#func _ready() -> void:
	#back_button.pressed.connect(close)
#
	#for i in slot_buttons.size():
		#slot_buttons[i].pressed.connect(on_slot_pressed.bind(i + 1))
		#delete_buttons[i].pressed.connect(on_delete_pressed.bind(i + 1))
#
#
#func open(mode: Mode) -> void:
	#_mode = mode
	#refresh()
	#focus_first_enabled()
#
#
#func refresh() -> void:
	#title_label.text = TITLES[_mode]
#
	#for i in slot_buttons.size():
		#var slot := i + 1
		#var meta: Variant = SaveAndLoad.slot_meta(slot)
#
		#slot_buttons[i].text = "%d.  %s" % [slot, describe(meta)]
		## 불러올 것이 없는 칸은 누를 수 없다. 저장과 새 게임은 빈 칸이 정상이다.
		#slot_buttons[i].disabled = _mode == Mode.LOAD and meta == null
		#delete_buttons[i].disabled = meta == null
#
#
### 어느 판인지 가늠하려면 게임 안 날짜와 실제 저장 시각이 둘 다 필요하다.
### 같은 날에 두 슬롯을 저장해두면 일차만으로는 구별되지 않는다.
#func describe(meta: Variant) -> String:
	#if meta is not Dictionary:
		#return "비어 있음"
#
	#return "%d일차  %s  %s" % [
		#meta.get("day", 0),
		#meta.get("level", "?"),
		#short_stamp(String(meta.get("saved_at", ""))),
	#]
#
#
### "2026-09-02T21:07:33"에서 월-일과 시:분만 남긴다. 연도와 초는 슬롯을 고르는 데 쓰이지 않는다.
#func short_stamp(stamp: String) -> String:
	#if stamp.length() < 16:
		#return ""
#
	#return "%s %s" % [stamp.substr(5, 5), stamp.substr(11, 5)]
#
#
### 불러오기에서는 첫 칸이 비어 눌리지 않을 수 있다. 그 칸에 포커스를 두면
### 키보드로 목록을 빠져나갈 수 없다.
#func focus_first_enabled() -> void:
	#for button in slot_buttons:
		#if not button.disabled:
			#button.grab_focus()
			#return
#
	#back_button.grab_focus()
#
#
#func on_slot_pressed(slot: int) -> void:
	#visible = false
	#slot_selected.emit(slot)
#
#
#func on_delete_pressed(slot: int) -> void:
	#SaveAndLoad.clear_slot(slot)
	#refresh()
	#focus_first_enabled()
#
#
#func close() -> void:
	#visible = false
	#closed.emit()
#
#
#func _unhandled_input(event: InputEvent) -> void:
	#if not visible:
		#return
#
	## 슬롯 목록이 열려 있을 때의 ESC는 게임 재개가 아니라 "뒤로가기"로 쓴다.
	#if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		#close()
		#get_viewport().set_input_as_handled()
