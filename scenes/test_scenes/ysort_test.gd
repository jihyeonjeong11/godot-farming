extends Node2D

## Y-sort 검증용 씬. 프롭은 전부 씬 트리에 박혀 있다 — 여기서는 아무것도 세우지
## 않는다. 배치를 다시 굽고 싶으면 tools/_gen_ysort_test.tscn 을 한 번 돌린다.
##
## 노드 프롭은 원점 Y, 타일 프롭은 셀 중앙 + y_sort_origin 이 정렬 키다.
## 오버레이의 초록 정렬선이 스프라이트 밑동에 붙어 있으면 제대로 잡힌 것이다.

@onready var level: Node2D = $Level
@onready var overlay: YSortDebugOverlay = $DebugOverlay
@onready var hud: Label = $UI/Hud

var _ground := Rect2(0, 0, 1200, 900)


func _ready() -> void:
	_measure_ground()
	_refresh_hud()
	queue_redraw()


## 바닥을 어디까지 깔지. 세워둔 것들을 다 덮을 만큼만.
func _measure_ground() -> void:
	var r := Rect2(0, 0, 640, 360)
	for child in level.get_children():
		var tl := child as TileMapLayer
		if tl != null and tl.tile_set != null:
			var used := tl.get_used_rect()
			var px := tl.tile_set.tile_size
			r = r.merge(Rect2(Vector2(used.position * px), Vector2(used.size * px)))
			continue
		var n := child as Node2D
		if n != null:
			r = r.merge(Rect2(n.position - Vector2(80, 200), Vector2(160, 240)))
	_ground = Rect2(Vector2.ZERO, r.end + Vector2(64, 64))


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_F1:
			overlay.visible = not overlay.visible
		KEY_F2:
			overlay.show_shapes = not overlay.show_shapes
		KEY_F3:
			overlay.show_sort_lines = not overlay.show_sort_lines
		KEY_F4:
			overlay.only_mismatched = not overlay.only_mismatched
		_:
			return
	_refresh_hud()


func _process(_delta: float) -> void:
	if overlay.checked > 0:
		hud.text = "%s   |   프롭 %d개 중 어긋남 %d개" % [
			_keys_text(), overlay.checked, overlay.mismatched]


func _refresh_hud() -> void:
	hud.text = _keys_text()


func _keys_text() -> String:
	return "F1 오버레이 %s   F2 콜리전 %s   F3 정렬선 %s   F4 어긋난 것만 %s   |  WASD 이동" % [
		"ON" if overlay.visible else "off",
		"ON" if overlay.show_shapes else "off",
		"ON" if overlay.show_sort_lines else "off",
		"ON" if overlay.only_mismatched else "off",
	]


func _draw() -> void:
	# 바닥 격자. 32px 는 타일 한 칸이라 눈대중 기준이 된다.
	var w := int(_ground.size.x)
	var h := int(_ground.size.y)
	draw_rect(Rect2(0, 0, w, h), Color(0.42, 0.38, 0.30))
	for x in range(0, w, 32):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(1, 1, 1, 0.05), 1.0)
	for y in range(0, h, 32):
		draw_line(Vector2(0, y), Vector2(w, y), Color(1, 1, 1, 0.05), 1.0)
