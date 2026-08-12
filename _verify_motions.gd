extends SceneTree
## Real path only: press a number key, left-click, see which body clip plays.

var _p: ApoPlayerNew

func _init() -> void:
	_p = (load("res://scenes/characters/player/player_new.tscn") as PackedScene).instantiate() as ApoPlayerNew
	root.add_child(_p)
	await physics_frame
	var sm := _p.state_machine
	var body := _p.sprite_layers[0]

	print("layers=%d (tool sprites: %s)  body clips=%d" % [
		_p.sprite_layers.size(),
		"none" if _p.sprite_layers.size() == 1 else "PRESENT",
		body.sprite_frames.get_animation_names().size()])
	print("\nkey  tool           body clip           frames  seconds")

	for i in ApoPlayerNew.TOOLS.size():
		sm.transition_to("Idle")
		await physics_frame
		await _tap_key(KEY_0 + i)
		await _click()
		await physics_frame

		var clip := str(body.animation)
		var want: String = ApoPlayerNew.TOOLS[i]
		var expect: String = _p.attack_action() + "_front"
		var frames: SpriteFrames = body.sprite_frames
		var ticks := 0
		while sm.current_node_state.name != "Idle" and ticks < 300:
			await physics_frame
			ticks += 1

		print("%s %d    %-14s %-19s %-7d %.2fs" % [
			"ok " if clip == expect and _p.equipped_tool == want else "BAD",
			i, want if not want.is_empty() else "(barehand)", clip,
			frames.get_frame_count(clip), ticks / float(Engine.physics_ticks_per_second)])

	_p.queue_free()
	quit(0)


func _tap_key(code: int) -> void:
	_send(code, true)
	await _wait(func(): return Input.is_physical_key_pressed(code as Key))
	await physics_frame
	_send(code, false)
	await _wait(func(): return not Input.is_physical_key_pressed(code as Key))


func _click() -> void:
	var d := InputEventMouseButton.new()
	d.button_index = MOUSE_BUTTON_LEFT
	d.pressed = true
	Input.parse_input_event(d)
	await _wait(func(): return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	var u := InputEventMouseButton.new()
	u.button_index = MOUSE_BUTTON_LEFT
	u.pressed = false
	Input.parse_input_event(u)


func _wait(cond: Callable) -> void:
	for _i in 40:
		if cond.call():
			return
		await physics_frame


func _send(code: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)
