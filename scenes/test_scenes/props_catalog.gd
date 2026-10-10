# 자동 생성 — tools/gen_prop_tiles.py --write 로 재생성한다. 직접 수정하지 말 것.
class_name PropsCatalog
extends RefCounted

# [source_id, atlas_coords, sprite_cells, footprint_cells]

const SMALL: Array[Array] = [
	[1, Vector2i(27, 15), Vector2i(2, 2), Vector2i(2, 2)],
	[1, Vector2i(16, 16), Vector2i(1, 1), Vector2i(1, 1)],
	[1, Vector2i(17, 16), Vector2i(2, 2), Vector2i(2, 2)],
	[1, Vector2i(26, 41), Vector2i(2, 2), Vector2i(2, 2)],
	[1, Vector2i(36, 42), Vector2i(2, 2), Vector2i(2, 2)],
	[1, Vector2i(38, 42), Vector2i(1, 1), Vector2i(1, 1)],
	[2, Vector2i(17, 29), Vector2i(2, 3), Vector2i(2, 1)],
	[2, Vector2i(23, 37), Vector2i(2, 3), Vector2i(2, 1)],
]

const MEDIUM: Array[Array] = [
	[1, Vector2i(9, 9), Vector2i(4, 5), Vector2i(4, 1)],
	[1, Vector2i(29, 14), Vector2i(4, 4), Vector2i(3, 1)],
	[1, Vector2i(9, 15), Vector2i(5, 3), Vector2i(5, 1)],
	[1, Vector2i(24, 15), Vector2i(3, 3), Vector2i(3, 1)],
	[1, Vector2i(33, 15), Vector2i(4, 3), Vector2i(4, 1)],
	[1, Vector2i(0, 18), Vector2i(8, 5), Vector2i(6, 1)],
	[1, Vector2i(16, 19), Vector2i(7, 5), Vector2i(5, 1)],
	[1, Vector2i(42, 35), Vector2i(4, 5), Vector2i(4, 1)],
	[1, Vector2i(22, 40), Vector2i(4, 4), Vector2i(3, 1)],
	[1, Vector2i(18, 41), Vector2i(4, 3), Vector2i(4, 1)],
	[1, Vector2i(28, 41), Vector2i(3, 3), Vector2i(3, 1)],
	[1, Vector2i(41, 41), Vector2i(5, 3), Vector2i(5, 1)],
	[1, Vector2i(47, 44), Vector2i(8, 5), Vector2i(6, 1)],
	[1, Vector2i(32, 45), Vector2i(7, 5), Vector2i(5, 1)],
	[2, Vector2i(19, 28), Vector2i(2, 4), Vector2i(2, 1)],
	[2, Vector2i(16, 32), Vector2i(3, 4), Vector2i(3, 1)],
	[2, Vector2i(20, 33), Vector2i(6, 3), Vector2i(5, 1)],
	[2, Vector2i(21, 36), Vector2i(2, 4), Vector2i(2, 1)],
	[2, Vector2i(23, 40), Vector2i(3, 4), Vector2i(3, 1)],
	[2, Vector2i(16, 41), Vector2i(6, 3), Vector2i(5, 1)],
	[2, Vector2i(16, 44), Vector2i(6, 4), Vector2i(6, 1)],
	[2, Vector2i(23, 45), Vector2i(3, 3), Vector2i(3, 1)],
]

const LARGE: Array[Array] = [
	[1, Vector2i(37, 12), Vector2i(7, 6), Vector2i(4, 1)],
	[1, Vector2i(44, 13), Vector2i(11, 7), Vector2i(6, 1)],
	[1, Vector2i(8, 18), Vector2i(8, 7), Vector2i(5, 1)],
	[1, Vector2i(23, 18), Vector2i(13, 8), Vector2i(6, 1)],
	[1, Vector2i(11, 38), Vector2i(7, 6), Vector2i(4, 1)],
	[1, Vector2i(0, 39), Vector2i(11, 7), Vector2i(6, 1)],
	[1, Vector2i(19, 44), Vector2i(13, 8), Vector2i(6, 1)],
	[1, Vector2i(39, 44), Vector2i(8, 7), Vector2i(5, 1)],
	[2, Vector2i(0, 0), Vector2i(9, 14), Vector2i(6, 1)],
	[2, Vector2i(9, 1), Vector2i(9, 13), Vector2i(6, 1)],
	[2, Vector2i(18, 2), Vector2i(10, 12), Vector2i(6, 1)],
	[2, Vector2i(19, 14), Vector2i(9, 14), Vector2i(6, 1)],
	[2, Vector2i(10, 15), Vector2i(9, 13), Vector2i(6, 1)],
	[2, Vector2i(0, 16), Vector2i(10, 12), Vector2i(6, 1)],
	[2, Vector2i(0, 28), Vector2i(8, 11), Vector2i(3, 1)],
	[2, Vector2i(8, 28), Vector2i(8, 11), Vector2i(3, 1)],
	[2, Vector2i(0, 39), Vector2i(8, 11), Vector2i(3, 1)],
	[2, Vector2i(8, 39), Vector2i(8, 11), Vector2i(3, 1)],
]
