class_name CursorUtils
extends RefCounted

# 마우스 커서 관련 utils
func on_cursor_movement() -> void:
	var cursor_pos = get_global_mouse_position()
	# ConversionUtils.pos_to_tile
	# SessionState.target_dict
	# pos
	# layers 어떤 타일맵 레이어가 겹치는지?
	# tile 아래에 겹친 타일 종류 back tilled watered
	# object 오브젝트와 겹치는지?
	# building 빌딩과 겹치는지?
	pass
