extends Node2D

const CROP_OBJECT := preload("res://world_objects/crops/crop_object.tscn")
const DATA_DIR := "res://world_objects/tres/crops"
const COLUMN_X: Array[float] = [0.0, 352.0, 1152.0, 1504.0]
const STAGE_GAP := 32.0
const ROW_GAP := 96.0
const CELL_ORIGIN := Vector2(16, 16) + CursorActions.CROP_BASE_OFFSET
const LABEL_OFFSET := Vector2(-16, -86)
const LABEL_FONT_SIZE := 10


func _ready() -> void:
	var files := Array(DirAccess.get_files_at(DATA_DIR)).filter(func(file: String) -> bool: return file.ends_with(".tres"))
	files.sort()
	for index in files.size():
		var data := load("%s/%s" % [DATA_DIR, files[index]]) as WorldObjectData
		var origin := Vector2(COLUMN_X[index % COLUMN_X.size()], floorf(float(index) / COLUMN_X.size()) * ROW_GAP + ROW_GAP) + CELL_ORIGIN
		_add_label(data, origin)
		for stage in data.growth_textures.size():
			_add_stage(data, stage, origin + Vector2(stage * STAGE_GAP, 0))


func _add_stage(data: WorldObjectData, stage: int, at: Vector2) -> void:
	var crop := CROP_OBJECT.instantiate() as CropObject
	crop.data = data
	crop.state["growth_stage"] = stage
	crop.position = at
	add_child(crop)


func _add_label(data: WorldObjectData, at: Vector2) -> void:
	var label := Label.new()
	label.text = "%s  max %d / %d" % [data.id, data.max_growth_stage, data.growth_textures.size()]
	label.position = at + LABEL_OFFSET
	label.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	add_child(label)
