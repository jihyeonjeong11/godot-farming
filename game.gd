# Persistent root. Shows the splash, then swaps the actual scene in under CurrentScene.
extends Node2D

@export_file("*.tscn") var scene_farm := "res://scenes/apo_test_scene_forest.tscn"
@export_file("*.tscn") var scene_city := "res://scenes/apo_test_scene_outside.tscn"
@export_file("*.tscn") var scene_mainmenu := "res://scenes/mainmenu.tscn"

@onready var current_scene: Node = $CurrentScene

# 전환 중 두 번째 요청이 끼어들어 씬이 두 개 붙는 걸 막는다.
var _swapping := false


func _ready() -> void:
	SignalBus.new_game_requested.connect(on_new_game_requested)
	SignalBus.load_game_requested.connect(on_load_game_requested)
	swap_scene(scene_mainmenu)


func on_new_game_requested() -> void:
	# 새 게임은 세이브를 무시한다. 각 레이어가 initial_objects로 시작하게 한다.
	SaveAndLoad.load_requested = false
	# 버튼 콜백이 실행 중인 그 프레임에 메뉴 자신을 트리에서 떼어내면
	# 눌린 버튼이 발밑을 잃는다. 물리/입력 처리가 끝난 뒤로 미룬다.
	swap_scene.call_deferred(scene_farm)


func on_load_game_requested() -> void:
	SaveAndLoad.load_requested = true
	# 인벤토리와 시간은 오토로드라 씬 교체와 무관하다. 여기서 바로 얹어도 된다.
	SaveAndLoad.load_inventory()
	SaveAndLoad.load_time()
	swap_scene.call_deferred(scene_farm)


## CurrentScene 밑의 내용만 교체한다. 루트(Game)와 시그널 연결은 그대로 살아남는다.
func swap_scene(path: String) -> void:
	if _swapping:
		return

	var packed := load(path) as PackedScene
	if packed == null:
		push_error("씬을 불러오지 못했다: %s" % path)
		return

	_swapping = true

	# queue_free만 하면 프레임 끝까지 옛 씬이 남아 새 씬과 겹친다.
	# 트리에서 먼저 떼어낸 뒤 해제한다.
	for child in current_scene.get_children():
		current_scene.remove_child(child)
		child.queue_free()

	current_scene.add_child(packed.instantiate())
	_swapping = false
