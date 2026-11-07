extends PanelContainer

const TITLE_SIZE := 40
const TEXT_SIZE := 28
const MUTED := Color(0.72, 0.72, 0.72)
const ACTIVE := Color(0.6, 0.85, 0.6)
const CROSSFADE := 0.5

const TRACKS := [
	{ "title": "Twin Ponds Hemlock", "path": "res://assets/sounds/musics/twin_ponds_hemlock.mp3" },
	{ "title": "Search One's Memory", "path": "res://assets/sounds/musics/search_one's_memory.mp3" },
	{ "title": "Not Feeling Well Today", "path": "res://assets/sounds/musics/not_feeling_well_today.mp3" },
	{ "title": "Thinking About How to Touch Your Hand", "path": "res://assets/sounds/musics/thinking_about_how_to_touch_your_hand.mp3" },
]

var _track_buttons: Array[Button] = []
var _now_label: Label
var _time_label: Label
var _progress: ProgressBar
var _play_button: Button
var _player: AudioStreamPlayer
var _index := -1
var _paused := false


func _ready() -> void:
	_build()
	_sync_with_sound_manager()
	_refresh()


func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(_player) or _player.stream == null:
		return
	var length := _player.stream.get_length()
	var pos := _player.get_playback_position()
	_progress.max_value = maxf(length, 0.01)
	_progress.value = pos
	_time_label.text = "%s / %s" % [_fmt(pos), _fmt(length)]


func _build() -> void:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 20)
	margin.add_child(root)

	root.add_child(_label("RADIO", TITLE_SIZE))
	root.add_child(HSeparator.new())

	_now_label = _label("", TEXT_SIZE)
	root.add_child(_now_label)

	_progress = ProgressBar.new()
	_progress.show_percentage = false
	_progress.custom_minimum_size.y = 14
	root.add_child(_progress)

	_time_label = _label("0:00 / 0:00", TEXT_SIZE, MUTED)
	_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_time_label)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 16)
	root.add_child(controls)
	controls.add_child(_button("이전", _on_prev_pressed))
	_play_button = _button("재생", _on_play_pressed)
	controls.add_child(_play_button)
	controls.add_child(_button("정지", _on_stop_pressed))
	controls.add_child(_button("다음", _on_next_pressed))

	root.add_child(HSeparator.new())

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 8)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(list)
	for i in TRACKS.size():
		var b := Button.new()
		b.text = "%d.  %s" % [i + 1, TRACKS[i].title]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size.y = 64
		b.add_theme_font_size_override("font_size", TEXT_SIZE)
		b.pressed.connect(_play_track.bind(i))
		list.add_child(b)
		_track_buttons.append(b)


func _sync_with_sound_manager() -> void:
	for stream: AudioStream in SoundManager.get_currently_playing_music():
		for i in TRACKS.size():
			if stream.resource_path == TRACKS[i].path:
				_index = i
	if _index < 0:
		return
	for p: AudioStreamPlayer in SoundManager.music.busy_players:
		if p.stream.resource_path == TRACKS[_index].path:
			_attach(p)
			_paused = p.stream_paused


func _play_track(index: int) -> void:
	_index = wrapi(index, 0, TRACKS.size())
	_paused = false
	var stream: AudioStream = load(TRACKS[_index].path)
	_attach(SoundManager.play_music(stream, CROSSFADE))
	_refresh()


func _attach(player: AudioStreamPlayer) -> void:
	if is_instance_valid(_player) and _player.finished.is_connected(_on_track_finished):
		_player.finished.disconnect(_on_track_finished)
	_player = player
	if is_instance_valid(_player):
		_player.finished.connect(_on_track_finished)


func _on_track_finished() -> void:
	_play_track(_index + 1)


func _on_play_pressed() -> void:
	if _index < 0 or not is_instance_valid(_player) or not SoundManager.is_music_playing():
		_play_track(maxi(_index, 0))
		return
	_paused = not _paused
	if _paused:
		SoundManager.pause_music()
	else:
		SoundManager.resume_music()
	_refresh()


func _on_stop_pressed() -> void:
	_attach(null)
	SoundManager.stop_music(CROSSFADE)
	_index = -1
	_paused = false
	_progress.value = 0
	_time_label.text = "0:00 / 0:00"
	_refresh()


func _on_prev_pressed() -> void:
	_play_track(_index - 1)


func _on_next_pressed() -> void:
	_play_track(_index + 1)


func _refresh() -> void:
	var playing := _index >= 0 and not _paused
	_play_button.text = "일시정지" if playing else "재생"
	if _index < 0:
		_now_label.text = "꺼짐"
	else:
		_now_label.text = ("일시정지 · " if _paused else "재생 중 · ") + TRACKS[_index].title
	for i in _track_buttons.size():
		var color := ACTIVE if i == _index else Color.WHITE
		_track_buttons[i].add_theme_color_override("font_color", color)
		_track_buttons[i].add_theme_color_override("font_hover_color", color)


func _button(text: String, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(160, 80)
	b.add_theme_font_size_override("font_size", TEXT_SIZE)
	b.pressed.connect(callback)
	return b


func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _fmt(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]
