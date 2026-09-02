## 상자 인벤토리 UI 를 PNG 로 떠서 눈으로 확인한다. --headless 없이 돌린다.
##   Godot_v4.7.1... --path . --resolution 1280x720 --script tools/_shot_container.gd -- <out_dir>
##
## 이 스크립트는 오토로드보다 먼저 컴파일되므로 Inventory 를 이름으로 쓸 수 없다.
## /root 에서 노드로 꺼내 쓴다.
extends SceneTree

const SCENE := "res://scenes/ui/inventory/container_inventory_ui.tscn"

var ui: CanvasLayer
var out_dir := "res://"
var frame := 0
var items: Array[Resource] = []


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]


func _open() -> void:
	items = _load_items()
	_fill_inventory()

	ui = (load(SCENE) as PackedScene).instantiate()
	root.add_child(ui)

	# 상자 칸을 흉내낸다. ContainerInventoryComponent 의 기본 칸수와 같은 12칸.
	var chest: Array[ItemStack] = []
	chest.resize(12)
	for i in mini(items.size(), 7):
		chest[i] = ItemStack.new(items[i], randi_range(1, 9))
	ui.setup(chest)


func _fill_inventory() -> void:
	var inv := root.get_node_or_null("/root/Inventory")
	if inv == null:
		push_warning("Inventory 오토로드를 찾지 못했다")
		return
	for item in items:
		for _n in randi_range(1, 4):
			inv.add_item(item)


func _load_items() -> Array[Resource]:
	var out: Array[Resource] = []
	for p in _find_items("res://scripts/resources"):
		out.append(load(p))
		if out.size() >= 8:
			break
	print("아이템 종류: %d" % out.size())
	return out


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
					and str(res.get_script().get_global_name()) == "Items":
				found.append(full)
		entry = dir.get_next()
	return found


func _process(_d: float) -> bool:
	frame += 1
	match frame:
		2:
			_open()
		10:
			_save("container_ui.png")
			return true
	return false


func _save(file_name: String) -> void:
	var img := root.get_texture().get_image()
	if img == null or img.get_width() == 0:
		push_warning("빈 이미지: %s" % file_name)
		return
	img.save_png(out_dir.path_join(file_name))
	print("저장: %s" % out_dir.path_join(file_name))
