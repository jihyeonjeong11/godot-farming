extends Node2D

@onready var characters: Array[CharacterBody2D] = [$Player, $PxCharacter]
@onready var camera: Camera2D = $Camera2D
@onready var info: Label = $CanvasLayer/Info

var active := 0


func _ready() -> void:
	_activate(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB:
		_activate(1 - active)
		get_viewport().set_input_as_handled()


func _activate(index: int) -> void:
	var from := characters[active]
	var to := characters[index]
	if from != to:
		to.global_position = from.global_position
		to.facing = from.facing
	for i in characters.size():
		characters[i].visible = i == index
		characters[i].process_mode = Node.PROCESS_MODE_INHERIT if i == index else Node.PROCESS_MODE_DISABLED
	active = index


func _process(_delta: float) -> void:
	camera.global_position = characters[active].global_position
	if active == 0:
		info.text = "[Tab] 전환  —  현재 스프라이트 (player.tscn)\nWASD 이동, 좌클릭 공격"
	else:
		info.text = "[Tab] 전환  —  새 버전 (rpgm_character_px)\n%s\n[1] 머리 [2] 셔츠 [3] 바지 [4] 신발 [5] 가방  누를 때마다 다음 색 → 없음,  [0] 전부 벗기/되돌리기\nWASD 이동, 좌클릭 공격, 우클릭 줍기(측면)" % characters[1].describe()
