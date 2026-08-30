## 생성된 도시를 PNG 로 떠서 눈으로 확인한다. 렌더링이 필요하므로 --headless 없이 돌린다.
##   Godot_v4.7.1... --path . --resolution 1600x900 --script tools/shot_city.gd -- <seed> <out_dir>
##
## 세 장을 찍는다:
##   city_wide.png — 도시 전체. 도로망과 존잉 분포.
##   house.png     — 집 한 채. 9-slice 와 가구 배치.
##   shop.png      — 상점 한 채. 회색 재질 쪽도 같이 본다.
extends SceneTree

const SCENE := "res://scenes/test_scenes/proc_gen_city_ruin.tscn"

# proc_gen_city_ruin.gd 의 Kind 이넘 값. 스크립트를 preload 하지 않고 값만 쓴다.
const KIND_HOUSE := 0
const KIND_SHOP := 1

var city: Node2D
var out_dir := "res://"
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var seed_val := int(args[0]) if args.size() > 0 else 12345
	if args.size() > 1:
		out_dir = args[1]

	city = (load(SCENE) as PackedScene).instantiate()
	city.world_seed = seed_val
	root.add_child(city)


func _process(_d: float) -> bool:
	frame += 1
	match frame:
		6:
			city.zoom_fit()
		10:
			_save("city_wide.png")
			_focus(_pick(KIND_HOUSE))
		14:
			_save("house.png")
			_focus(_pick(KIND_SHOP))
		18:
			_save("shop.png")
			return true
	return false


func _pick(kind: int) -> Dictionary:
	for b: Dictionary in city.placed_buildings:
		if b.has("rect") and b["kind"] == kind:
			return b
	return {}


## 건물 한 채가 화면에 꽉 차게 카메라를 맞춘다. 카메라가 플레이어 자식이라 플레이어를 옮긴다.
func _focus(b: Dictionary) -> void:
	if b.is_empty():
		print("  대상 없음")
		return
	var r: Rect2i = b["rect"]
	print("  chunk=%s face=%d rect=%s" % [b.get("chunk", "?"), b["face"], str(r)])
	var mid := Vector2(r.position) + Vector2(r.size) * 0.5
	city.get_node("Player").position = mid * float(city.TILE_PX)
	var tile_px: float = float(city.TILE_PX)
	var px := (Vector2(r.size) + Vector2.ONE * 4.0) * tile_px
	var vp := root.get_visible_rect().size
	var cam := city.get_node("Player/Camera2D") as Camera2D
	cam.zoom = Vector2.ONE * minf(vp.x / px.x, vp.y / px.y)


func _save(name: String) -> void:
	var img := root.get_texture().get_image()
	var path := out_dir.path_join(name)
	var err := img.save_png(path)
	print("%s -> %s (%dx%d)" % ["saved" if err == OK else "FAILED", path, img.get_width(), img.get_height()])
