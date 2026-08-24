extends Control

## 닫힐 때 부모 메뉴가 다시 뜨도록 알린다.
signal closed

@onready var visual_button: Button = %Visual
@onready var windowed_button: Button = %WindowedButton
@onready var fullscreen_button: Button = %FullscreenButton
@onready var audio_button: Button = %Audio
@onready var master_slider: HSlider = %MasterVolumeSlider
@onready var master_value: Label = %MasterVolumeValue
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(close)
	windowed_button.pressed.connect(on_windowed_pressed)
	fullscreen_button.pressed.connect(on_fullscreen_pressed)

	# 저장된 값을 슬라이더에 먼저 얹은 뒤 연결한다.
	# 순서를 뒤집으면 초기화 자체가 value_changed를 쏴서 볼륨을 덮어쓴다.
	master_slider.set_value_no_signal(Settings.master_volume)
	master_value.text = "%d" % master_slider.value
	master_slider.value_changed.connect(on_master_volume_changed)


func open() -> void:
	visible = true
	refresh()
	visual_button.grab_focus()


## 실제 반영과 저장은 Settings가 한다. 이 화면은 값을 넘기고 표시만 맞춘다.
func on_master_volume_changed(value: float) -> void:
	Settings.set_master_volume(value)
	master_value.text = "%d" % value


func on_windowed_pressed() -> void:
	Settings.set_window_mode("windowed")
	refresh_window_buttons()


func on_fullscreen_pressed() -> void:
	Settings.set_window_mode("fullscreen")
	refresh_window_buttons()


## 다시 열 때마다 저장된 값으로 화면을 맞춘다. 슬라이더를 건드리다 ESC로 나갔다
## 들어와도 표시와 실제 값이 어긋나지 않는다.
func refresh() -> void:
	master_slider.set_value_no_signal(Settings.master_volume)
	master_value.text = "%d" % master_slider.value
	refresh_window_buttons()


## 지금 모드인 쪽 버튼을 눌러도 의미가 없으므로 비활성화해 현재 상태를 드러낸다.
func refresh_window_buttons() -> void:
	var is_fullscreen := Settings.current_window_mode() == "fullscreen"

	windowed_button.disabled = not is_fullscreen
	fullscreen_button.disabled = is_fullscreen


func close() -> void:
	visible = false
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# 세팅이 열려 있을 때의 ESC는 게임 재개가 아니라 "뒤로가기"로 쓴다.
	if event.is_action_pressed("pause") or event.is_action_pressed("ingame_pause"):
		close()
		get_viewport().set_input_as_handled()
