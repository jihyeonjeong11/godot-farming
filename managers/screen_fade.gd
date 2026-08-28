class_name ScreenFade
extends CanvasLayer
## 화면을 검게 덮었다 걷는 오버레이.
##
## game.tscn 에 매달려 있다. swap_scene 은 CurrentScene 의 자식만 갈아끼우니
## 씬이 바뀌어도 이건 안 죽는다. 씬에 박아둔 값 두 가지가 중요하다.
## layer 100 - 스플래시(layer 128) 아래, 그 밖의 UI 위.
## process_mode ALWAYS - 일시정지 중에도 걷혀야 한다. 캄캄한 채로 멈추면
## 빠져나올 길이 없다.

const DEFAULT_DURATION: float = 0.4

## 트리에 하나뿐이다. 침대처럼 아무 데서나 부르는 쪽이 노드를 찾아 헤매지
## 않도록 자기 자신을 여기 걸어둔다. 오토로드였을 때의 호출부를 그대로 둔다.
static var instance: ScreenFade

var _backdrop: ColorRect
var _tween: Tween


static func fade_out(duration: float = DEFAULT_DURATION) -> void:
	if not _alive():
		return
	await instance._fade_to(1.0, duration)


static func fade_in(duration: float = DEFAULT_DURATION) -> void:
	if not _alive():
		return
	await instance._fade_to(0.0, duration)
	instance._backdrop.visible = false


## 없어도 부르는 쪽을 멈춰 세우지는 않는다. 페이드가 빠진 채로 진행되는 편이
## 캄캄한 화면에 갇히는 것보다 낫다.
static func _alive() -> bool:
	if instance == null or not is_instance_valid(instance):
		push_warning("ScreenFade 가 트리에 없다. game.tscn 을 확인해라.")
		return false
	return true


func _ready() -> void:
	instance = self

	_backdrop = ColorRect.new()
	_backdrop.color = Color(0, 0, 0, 0)
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 투명해도 Control 은 클릭을 먹는다. 꺼두지 않으면 밭 갈기까지 통째로 죽는다.
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.visible = false
	add_child(_backdrop)


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _fade_to(alpha: float, duration: float) -> void:
	# 앞선 페이드가 남아 있으면 둘이 같은 색을 서로 당긴다.
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_backdrop.visible = true

	_tween = create_tween()
	_tween.tween_property(_backdrop, "color:a", alpha, duration)
	await _tween.finished
