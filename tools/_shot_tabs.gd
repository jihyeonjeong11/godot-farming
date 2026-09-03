## 탭 인게임 메뉴를 PNG 로 떠서 눈으로 확인한다. 렌더링이 필요하므로 --headless 없이 돌린다.
##   Godot_v4.7.1... --path . --resolution 1280x720 --script tools/_shot_tabs.gd -- <out_dir>
##
## 인벤토리에 아이템 몇 개를 넣고 탭을 하나씩 눌러가며 찍는다.
## 이 스크립트 자체는 오토로드보다 먼저 컴파일되므로 Inventory 를 이름으로 쓸 수 없다.
## /root 에서 노드로 꺼내 쓴다.
extends SceneTree

const SCENE := "res://scenes/ui/scene_ingame_overlay_menu.tscn"

var menu: CanvasLayer
var out_dir := "res://"
var frame := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]


func _ready_menu() -> void:
	_fill_inventory()

	menu = (load(SCENE) as PackedScene).instantiate()
	root.add_child(menu)
	menu.visible = true


## 빈 칸만 있으면 그리드 느낌이 안 산다. 있는 아이템 리소스를 긁어 몇 칸 채운다.
func _fill_inventory() -> void:
	var inv := root.get_node_or_null("/root/Inventory")
	if inv == null:
		push_warning("Inventory 오토로드를 찾지 못했다")
		return

	var count := 0
	for p in _find_items("res://scripts/resources"):
		var item := load(p)
		for _n in randi_range(1, 4):
			inv.add_item(item)
		count += 1
		if count >= 8:
			break
	print("채운 아이템 종류: %d" % count)


func _find_items(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var full := dir_path.path_join(entry)
		if dir.current_is_dir():
			found.append_array(_find_items(full))
		elif entry.ends_with(".tres"):
			var res := load(full)
			if res != null and res.get_script() != null \
					and str(res.get_script().get_global_name()) == "Item":
				found.append(full)
		entry = dir.get_next()
	return found


func _process(_d: float) -> bool:
	frame += 1
	match frame:
		2:
			_ready_menu()
		8:
			menu.show_tab(0)
		12:
			_save("tabs_inventory.png")
			menu.show_tab(1)
		16:
			_save("tabs_crafting.png")
			menu.show_tab(2)
		20:
			_save("tabs_stats.png")
			menu.show_tab(3)
		24:
			_save("tabs_settings.png")
			return true
	return false


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	if img == null or img.get_width() == 0:
		push_warning("빈 이미지: %s" % file_name)
		return
	img.save_png(out_dir.path_join(file_name))
	print("저장: %s" % out_dir.path_join(file_name))
