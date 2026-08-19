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

const MASTER_BUS := "Master"


func _ready() -> void:
	back_button.pressed.connect(close)
	windowed_button.pressed.connect(on_windowed_pressed)
	fullscreen_button.pressed.connect(on_fullscreen_pressed)

	# 현재 버스 볼륨을 슬라이더에 먼저 반영한 뒤 연결한다.
	# 순서를 뒤집으면 초기화 자체가 value_changed를 쏴서 볼륨을 덮어쓴다.
	master_slider.set_value_no_signal(get_master_volume())
	master_value.text = "%d" % master_slider.value
	master_slider.value_changed.connect(on_master_volume_changed)


func open() -> void:
	visible = true
	refresh_window_buttons()
	visual_button.grab_focus()


## 버스 볼륨(dB)을 0~100 스케일로 되돌린다.
func get_master_volume() -> float:
	var bus := AudioServer.get_bus_index(MASTER_BUS)
	if AudioServer.is_bus_mute(bus):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus)) * 100.0


func on_master_volume_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index(MASTER_BUS)

	# linear_to_db(0)은 -inf라 그대로 넣지 않고 음소거로 처리한다.
	if value <= 0.0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))

	master_value.text = "%d" % value


func on_windowed_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	refresh_window_buttons()


func on_fullscreen_pressed() -> void:
	# 독점(EXCLUSIVE) 대신 보더리스. 알트탭이 빠르고 멀티모니터에서 안전하다.
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	refresh_window_buttons()


## 지금 모드인 쪽 버튼을 눌러도 의미가 없으므로 비활성화해 현재 상태를 드러낸다.
func refresh_window_buttons() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

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
