class_name YSortDebugOverlay
extends Node2D

## Level 밑을 훑어서 콜리전 도형과 Y-sort 기준선을 전부 그린다.
##
## 노드 프롭의 정렬 키는 노드 원점 Y 하나뿐이고, 타일 프롭은 셀 중앙 Y +
## y_sort_origin 이다. 어느 쪽이든 그 선이 아트 밑동에 붙어 있어야 플레이어가
## 앞에 섰을 때 제대로 비켜준다. 어긋난 만큼을 프롭 이름 옆에 px 로 찍는다.

const C_STATIC := Color(0.35, 0.7, 1.0)
const C_AREA := Color(1.0, 0.35, 0.55)
const C_CHAR := Color(1.0, 0.85, 0.2)
const C_OTHER := Color(0.6, 1.0, 0.5)
const C_TILE := Color(0.55, 0.85, 1.0)
const C_SORT := Color(0.2, 1.0, 0.3)
const C_BAD := Color(1.0, 0.45, 0.25)
const C_BOUNDS := Color(1.0, 1.0, 1.0, 0.25)

const TOLERANCE := 1.5

@export var target: Node2D
@export var show_shapes := true
@export var show_sort_lines := true
## 켜면 정렬선이 밑동과 어긋난 것만 그린다. 프롭이 많을 때 훑기 좋다.
@export var only_mismatched := false

var checked := 0
var mismatched := 0

var _font: Font
var _trim: Dictionary = {}


func _ready() -> void:
	top_level = true
	z_index = 4096
	_font = ThemeDB.fallback_font
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if target == null:
		return
	checked = 0
	mismatched = 0
	for child in target.get_children():
		var tl := child as TileMapLayer
		if tl != null:
			_draw_tilemap(tl)
			continue
		var n := child as Node2D
		if n != null and show_sort_lines:
			_draw_node_prop(n)
	if show_shapes:
		_walk(target)


# ── 노드 프롭 ────────────────────────────────────────────────

func _draw_node_prop(n: Node2D) -> void:
	var o := n.global_position
	var rect := _visual_bounds(n)
	var gap := 0.0
	if rect != Rect2():
		gap = rect.end.y - o.y
	_mark(o, rect, String(n.name), gap, 60.0)


## 스프라이트가 실제로 차지하는 화면 사각형. 투명 여백은 빼고 잰다 —
## 텍스처 사각형으로 재면 밑에 남은 여백만큼 늘 어긋나 보인다.
func _visual_bounds(n: Node) -> Rect2:
	var out := Rect2()
	var first := true
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var cur := stack.pop_back() as Node
		for c in cur.get_children():
			stack.push_back(c)
		var r := Rect2()
		var sp := cur as Sprite2D
		if sp != null and sp.visible and sp.texture != null:
			r = _trimmed(sp.texture, sp.centered, sp.offset)
		var asp := cur as AnimatedSprite2D
		if asp != null and asp.visible and asp.sprite_frames != null:
			var tex := asp.sprite_frames.get_frame_texture(asp.animation, asp.frame)
			if tex != null:
				r = _trimmed(tex, asp.centered, asp.offset)
		if r == Rect2():
			continue
		var ci := cur as CanvasItem
		var gr := ci.get_global_transform() * r
		out = gr if first else out.merge(gr)
		first = false
	return out


## 텍스처의 불투명 영역을 노드 로컬 좌표로 옮긴 사각형. 텍스처마다 한 번만 잰다.
func _trimmed(tex: Texture2D, centered: bool, offset: Vector2) -> Rect2:
	var key := tex.get_instance_id()
	var used: Rect2i = _trim.get(key, Rect2i())
	if not _trim.has(key):
		var img := tex.get_image()
		used = img.get_used_rect() if img != null else Rect2i(Vector2i.ZERO, tex.get_size())
		if used.size == Vector2i.ZERO:
			used = Rect2i(Vector2i.ZERO, tex.get_size())
		_trim[key] = used
	var base := offset
	if centered:
		base -= tex.get_size() * 0.5
	return Rect2(base + Vector2(used.position), Vector2(used.size))


# ── 타일 프롭 ────────────────────────────────────────────────

func _draw_tilemap(tl: TileMapLayer) -> void:
	var ts := tl.tile_set
	if ts == null:
		return
	var gx := tl.get_global_transform()
	for cell: Vector2i in tl.get_used_cells():
		var src := ts.get_source(tl.get_cell_source_id(cell)) as TileSetAtlasSource
		if src == null:
			continue
		var coords := tl.get_cell_atlas_coords(cell)
		var td := src.get_tile_data(coords, 0)
		if td == null:
			continue
		var center := tl.map_to_local(cell)
		# 타일의 정렬 키. 셀 중앙에서 y_sort_origin 만큼 내린 자리다.
		var sort_pos := gx * (center + Vector2(0, td.y_sort_origin))
		var region := src.get_tile_texture_region(coords, 0)
		var draw_pos := center - Vector2(region.size) * 0.5 - Vector2(td.texture_origin)
		var used := _trim_region(src.texture, region)
		var art := Rect2(gx * (draw_pos + Vector2(used.position)), Vector2(used.size))
		if show_sort_lines:
			_mark(sort_pos, art, "%d:%d" % [coords.x, coords.y], art.end.y - sort_pos.y,
				maxf(24.0, art.size.x * 0.5))
		if show_shapes:
			_draw_tile_collisions(td, ts, gx * center)


func _draw_tile_collisions(td: TileData, ts: TileSet, center: Vector2) -> void:
	for layer in ts.get_physics_layers_count():
		for i in td.get_collision_polygons_count(layer):
			var pts := td.get_collision_polygon_points(layer, i)
			if pts.size() < 3:
				continue
			var moved := PackedVector2Array()
			for p in pts:
				moved.append(center + p)
			moved.append(center + pts[0])
			draw_polyline(moved, C_TILE, 1.0)


func _trim_region(tex: Texture2D, region: Rect2i) -> Rect2i:
	var key := "%d:%d,%d,%d,%d" % [tex.get_instance_id(),
		region.position.x, region.position.y, region.size.x, region.size.y]
	if _trim.has(key):
		return _trim[key]
	var used := Rect2i(Vector2i.ZERO, region.size)
	var img := tex.get_image()
	if img != null:
		var u := img.get_region(region).get_used_rect()
		if u.size != Vector2i.ZERO:
			used = u
	_trim[key] = used
	return used


# ── 공통 ─────────────────────────────────────────────────────

## 정렬선 + 아트 사각형 + 어긋난 px. gap 이 0 이면 밑동에 붙은 것이다.
func _mark(sort_pos: Vector2, art: Rect2, label: String, gap: float, half_w: float) -> void:
	checked += 1
	var ok := absf(gap) < TOLERANCE
	if not ok:
		mismatched += 1
	if only_mismatched and ok:
		return
	var col := C_SORT if ok else C_BAD
	if art != Rect2():
		draw_rect(art, C_BOUNDS, false, 1.0)
	draw_line(sort_pos - Vector2(half_w, 0), sort_pos + Vector2(half_w, 0), col, 1.0)
	draw_line(sort_pos - Vector2(0, 5), sort_pos + Vector2(0, 5), col, 1.0)
	draw_circle(sort_pos, 2.0, col)
	var text := label
	if not ok:
		text = "%s %+.1f" % [label, gap]
	draw_string(_font, sort_pos + Vector2(4, -5), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)


func _walk(n: Node) -> void:
	for c in n.get_children():
		var cs := c as CollisionShape2D
		if cs != null and cs.shape != null and not cs.disabled:
			_draw_shape(cs.get_global_transform(), cs.shape, _color_for(cs))
		var cp := c as CollisionPolygon2D
		if cp != null and not cp.disabled and cp.polygon.size() > 2:
			draw_set_transform_matrix(cp.get_global_transform())
			draw_polyline(cp.polygon + PackedVector2Array([cp.polygon[0]]), _color_for(cp), 1.0)
			draw_set_transform_matrix(Transform2D.IDENTITY)
		_walk(c)


func _color_for(node: Node) -> Color:
	var p := node.get_parent()
	if p is StaticBody2D:
		return C_STATIC
	if p is Area2D:
		return C_AREA
	if p is CharacterBody2D or p is RigidBody2D:
		return C_CHAR
	return C_OTHER


func _draw_shape(gt: Transform2D, shape: Shape2D, col: Color) -> void:
	draw_set_transform_matrix(gt)
	var rect := shape as RectangleShape2D
	if rect != null:
		draw_rect(Rect2(-rect.size * 0.5, rect.size), col, false, 1.0)
	var circle := shape as CircleShape2D
	if circle != null:
		draw_arc(Vector2.ZERO, circle.radius, 0.0, TAU, 24, col, 1.0)
	var cap := shape as CapsuleShape2D
	if cap != null:
		var half := maxf(cap.height * 0.5 - cap.radius, 0.0)
		draw_arc(Vector2(0, -half), cap.radius, PI, TAU, 12, col, 1.0)
		draw_arc(Vector2(0, half), cap.radius, 0.0, PI, 12, col, 1.0)
		draw_line(Vector2(-cap.radius, -half), Vector2(-cap.radius, half), col, 1.0)
		draw_line(Vector2(cap.radius, -half), Vector2(cap.radius, half), col, 1.0)
	var poly := shape as ConvexPolygonShape2D
	if poly != null and poly.points.size() > 2:
		draw_polyline(poly.points + PackedVector2Array([poly.points[0]]), col, 1.0)
	var seg := shape as SegmentShape2D
	if seg != null:
		draw_line(seg.a, seg.b, col, 1.0)
	draw_set_transform_matrix(Transform2D.IDENTITY)
