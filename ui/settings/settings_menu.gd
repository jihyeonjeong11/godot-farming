class_name SettingsMenu extends Control


signal closed()


@onready var settings_anchor: PanelAnchor = %PanelAnchor

@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var settings_menu: Menu = %Menu
@onready var sounds_volume_slider: HSlider = %SoundsVolumeSlider
@onready var sounds_volume_value: Label = %SoundsVolumeValue
@onready var ui_sounds_volume_slider: HSlider = %UISoundsVolumeSlider
@onready var ui_sounds_volume_value: Label = %UISoundsVolumeValue
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_value: Label = %MusicVolumeValue
@onready var full_screen: BaseCheckbox = %FullScreen


func _ready() -> void :
	await get_tree().process_frame

	settings_menu.call_deferred("focus_first_item")

	Settings.settings_reset.connect(_update_settings_ui)
	_update_settings_ui()

	settings_anchor.appear()





func _update_settings_ui() -> void :
	sounds_volume_slider.value = Settings.sounds_volume
	sounds_volume_value.text = str(Settings.sounds_volume * 10).replace(".0", "")
	ui_sounds_volume_slider.value = Settings.ui_sounds_volume
	ui_sounds_volume_value.text = str(Settings.ui_sounds_volume * 10).replace(".0", "")
	music_volume_slider.value = Settings.music_volume
	music_volume_value.text = str(Settings.music_volume * 10).replace(".0", "")

	full_screen.button_pressed = Settings.full_screen_is_on


func _on_settings_menu_actioned(item: Control) -> void :
	match item.name:
		"FullScreen":
			full_screen.button_pressed = not full_screen.button_pressed
			_on_full_screen_toggled(full_screen.button_pressed)

		"Reset":
			Settings.reset_all_settings()


func _on_settings_menu_cancelled() -> void :
	Settings.save_settings()
	await settings_anchor.disappear()
	closed.emit()
	queue_free()


func _on_sounds_volume_slider_value_changed(value) -> void :
	Settings.sounds_volume = value


func _on_music_volume_slider_value_changed(value) -> void :
	Settings.music_volume = value


func _on_sounds_volume_gui_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_right") and ( not "axis_value" in event or event.axis_value == 1):
		accept_event()
		Settings.sounds_volume = clamp(Settings.sounds_volume + 0.1, 0, 1)
		SoundManager.play_sound(settings_menu.actioned_sound, "SFX")
		sounds_volume_slider.value = Settings.sounds_volume
		sounds_volume_value.text = str(Settings.sounds_volume * 10).replace(".0", "")

	if event.is_action_pressed("ui_left") and ( not "axis_value" in event or event.axis_value == -1):
		accept_event()
		Settings.sounds_volume = clamp(Settings.sounds_volume - 0.1, 0, 1)
		SoundManager.play_sound(settings_menu.actioned_sound, "SFX")
		sounds_volume_slider.value = Settings.sounds_volume
		sounds_volume_value.text = str(Settings.sounds_volume * 10).replace(".0", "")


func _on_ui_sounds_volume_gui_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_right") and ( not "axis_value" in event or event.axis_value == 1):
		accept_event()
		Settings.ui_sounds_volume = clamp(Settings.ui_sounds_volume + 0.1, 0, 1)
		SoundManager.play_ui_sound(settings_menu.actioned_sound, "UI")
		ui_sounds_volume_slider.value = Settings.ui_sounds_volume
		ui_sounds_volume_value.text = str(Settings.ui_sounds_volume * 10).replace(".0", "")

	if event.is_action_pressed("ui_left") and ( not "axis_value" in event or event.axis_value == -1):
		accept_event()
		Settings.ui_sounds_volume = clamp(Settings.ui_sounds_volume - 0.1, 0, 1)
		SoundManager.play_ui_sound(settings_menu.actioned_sound, "UI")
		ui_sounds_volume_slider.value = Settings.ui_sounds_volume
		ui_sounds_volume_value.text = str(Settings.ui_sounds_volume * 10).replace(".0", "")


func _on_music_volume_gui_input(event: InputEvent) -> void :
	if event.is_action_pressed("ui_right") and ( not "axis_value" in event or event.axis_value == 1):
		accept_event()
		Settings.music_volume = clamp(Settings.music_volume + 0.1, 0, 1)
		SoundManager.play_ui_sound(settings_menu.actioned_sound, "Music")
		music_volume_slider.value = Settings.music_volume
		music_volume_value.text = str(Settings.music_volume * 10).replace(".0", "")

	if event.is_action_pressed("ui_left") and ( not "axis_value" in event or event.axis_value == -1):
		accept_event()
		Settings.music_volume = clamp(Settings.music_volume - 0.1, 0, 1)
		SoundManager.play_ui_sound(settings_menu.actioned_sound, "Music")
		music_volume_slider.value = Settings.music_volume
		music_volume_value.text = str(Settings.music_volume * 10).replace(".0", "")


func _on_full_screen_toggled(toggled_on: bool) -> void :
	Settings.full_screen_is_on = toggled_on
