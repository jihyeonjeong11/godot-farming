extends SceneTree
## junk 아이템 리소스 100개가 전부 로드되는지, 아틀라스 영역이 제 칸을 가리키는지 확인한다.
## 실행: --headless --path . --script tools/_verify_junk_items.gd

const DIR := "res://scripts/resources/junk"


func _init() -> void:
	var dir := DirAccess.open(DIR)
	if dir == null:
		push_error("폴더를 못 열었다: %s" % DIR)
		quit(1)
		return

	var ids: Dictionary = {}
	var regions: Dictionary = {}
	var count := 0
	var bad := 0

	for file_name in dir.get_files():
		if not file_name.ends_with(".tres"):
			continue
		count += 1
		var path := "%s/%s" % [DIR, file_name]
		var res: Resource = load(path)
		if res == null:
			print("LOAD FAIL: ", path)
			bad += 1
			continue

		var id: String = res.get("item_id")
		if id.is_empty():
			print("EMPTY ID: ", path)
			bad += 1
		elif ids.has(id):
			print("DUP ID: ", id, " <- ", path, " / ", ids[id])
			bad += 1
		else:
			ids[id] = path

		if id != file_name.get_basename():
			print("NAME MISMATCH: ", path, " item_id=", id)
			bad += 1

		var tex: AtlasTexture = res.get("item_texture")
		if tex == null or tex.atlas == null:
			print("NO TEXTURE: ", path)
			bad += 1
			continue

		var r := tex.region
		if r.size != Vector2(32, 32) or int(r.position.x) % 32 != 0 or int(r.position.y) % 32 != 0:
			print("BAD REGION: ", path, " ", r)
			bad += 1
		var key := "%d,%d" % [r.position.x, r.position.y]
		if regions.has(key):
			print("DUP REGION: ", key, " <- ", path, " / ", regions[key])
			bad += 1
		else:
			regions[key] = path

		if res.get("item_type") != "junk":
			print("NOT JUNK: ", path)
			bad += 1

	print("검사한 파일 %d개, 문제 %d건, 서로 다른 칸 %d개" % [count, bad, regions.size()])
	quit(1 if (bad > 0 or count != 100) else 0)
