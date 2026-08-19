class_name PortalComponent
extends Area2D
## 밟으면 다른 씬으로 넘어가는 문.
##
## 어디로 갈지만 알고, 실제 교체는 game.gd가 한다. 여기서 직접 씬을 갈아끼우면
## 루트(Game)와 오토로드 연결이 끊긴 채로 바뀌므로 SignalBus를 통로로 쓴다.

@export_file("*.tscn") var target_scene: String = ""


func _ready() -> void:
	body_entered.connect(on_body_entered)


func on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if target_scene.is_empty():
		push_warning("포탈에 target_scene이 비어 있습니다: %s" % get_path())
		return

	# 교체가 예약된 뒤에도 이 프레임 안에서 body_entered가 한 번 더 울릴 수 있다.
	# 그때 씬 교체가 두 번 예약되면 씬이 두 개 붙으므로 여기서 먼저 잠근다.
	set_deferred("monitoring", false)

	# game.tscn을 거치지 않고 이 씬만 단독 실행(F6)하면 Game 루트가 없어서
	# 신호를 받을 사람이 없다. 그때는 직접 갈아끼운다. 오토로드는 어차피 살아남는다.
	if SignalBus.scene_change_requested.get_connections().is_empty():
		get_tree().change_scene_to_file.call_deferred(target_scene)
		return

	SignalBus.scene_change_requested.emit(target_scene)
