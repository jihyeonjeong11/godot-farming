## 프리팹 한 칸을 PNG 로 떠서 눈으로 확인한다. 렌더링이 필요하므로 --headless 없이 돌린다.
##   Godot_v4.7.1... --path . --script tools/shot_prefab.gd -- <prefab.tscn> <out_dir>
extends SceneTree

const CELL := 16
const TILE_PX := 32

var scene_path := "res://scenes/prefabs/park.tscn"
var cam: Camera2D
var out_dir := "res://"
var out_name := "prefab.png"
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		scene_path = args[0]
	if args.size() > 1:
		out_dir = args[1]
	out_name = scene_path.get_file().get_basename() + ".png"

	var holder := Node2D.new()
	root.add_child(holder)
	holder.add_child((load(scene_path) as PackedScene).instantiate())

	# 프리팹 한 칸(16x16 타일)이 화면에 꽉 차게.
	cam = Camera2D.new()
	holder.add_child(cam)


func _process(_d: float) -> bool:
	frame += 1
	# 카메라는 트리에 들어간 뒤라야 current 로 만들 수 있다.
	if frame == 1:
		var px := float(CELL * TILE_PX)
		var vp := root.get_visible_rect().size
		cam.position = Vector2.ONE * px * 0.5
		cam.zoom = Vector2.ONE * minf(vp.x / px, vp.y / px)
		cam.make_current()
	if frame < 8:
		return false
	var img := root.get_texture().get_image()
	var path := out_dir.path_join(out_name)
	var err := img.save_png(path)
	print("%s -> %s (%dx%d)" % ["saved" if err == OK else "FAILED", path, img.get_width(), img.get_height()])
	return true
