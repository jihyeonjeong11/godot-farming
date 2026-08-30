extends Sprite2D
## 우클릭하면 안으로 들어가는 문.
##
## 밟으면 열리는 PortalComponent 와 달리 상호작용을 기다린다. 어디로 갈지만
## 알고 실제 씬 교체는 game.gd 가 한다. 여기서 직접 갈아끼우면 루트(Game)와
## 오토로드 연결이 끊긴 채로 바뀐다.

@export_file("*.tscn") var target_scene: String = ""
## 도착한 씬의 SpawnPoint 이름. 비우면 그 씬에 박힌 자리에 그대로 선다.
@export var target_spawn: StringName = &""


## ObjectCursorComponent 가 interactables 그룹을 훑어 이 메서드를 부른다.
func interact() -> void:
	if target_scene.is_empty():
		push_warning("문에 target_scene 이 비어 있다: %s" % get_path())
		return

	SignalBus.scene_change_requested.emit(target_scene, target_spawn)
