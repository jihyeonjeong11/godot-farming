@tool
class_name WorldObject
extends Node2D

## 월드에 놓인 오브젝트 하나. def(ObjectDef)를 받아 그림을 그리고,
## 원점(position)은 그림의 발밑 가운데다. y-sort와 격자 배치가 이 점을 기준으로 한다.

const GROUP := &"world_object"

## 같은 texture 를 쓰는 오브젝트끼리 SpriteFrames 를 공유한다.
static var _static_frames: Dictionary = {}
## texture → 불투명 영역(Rect2). interact_rect 자동 계산용.
static var _used_rect_cache: Dictionary = {}

@export var def: ObjectDef:
	set(value):
		def = value
		if is_node_ready():
			_apply_def()

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_apply_def()
	if Engine.is_editor_hint():
		return
	add_to_group(GROUP)


func _apply_def() -> void:
	var frames := _frames_for(def)
	sprite.sprite_frames = frames
	if frames == null:
		return

	var anim := def.default_animation if frames.has_animation(def.default_animation) else &"default"
	sprite.play(anim)
	# 그림 아래 가운데를 원점에 맞춘다.
	var size := _current_texture_size()
	sprite.centered = true
	sprite.offset = Vector2(0, -size.y * 0.5) + def.sprite_offset


## 커서 선택 영역(로컬 좌표).
func interact_rect() -> Rect2:
	if def != null and def.interact_rect.has_area():
		return def.interact_rect
	var tex := current_texture()
	if tex == null:
		return Rect2()
	var size := tex.get_size()
	var used := _used_rect(tex)
	return Rect2(sprite.offset - size * 0.5 + used.position, used.size)


func global_interact_rect() -> Rect2:
	return global_transform * interact_rect()


func current_texture() -> Texture2D:
	if sprite.sprite_frames == null:
		return null
	return sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)


func _current_texture_size() -> Vector2:
	var tex := current_texture()
	return tex.get_size() if tex != null else Vector2.ZERO


static func _frames_for(d: ObjectDef) -> SpriteFrames:
	if d == null:
		return null
	if d.sprite_frames != null:
		return d.sprite_frames
	if d.texture == null:
		return null
	if not _static_frames.has(d.texture):
		var frames := SpriteFrames.new() # "default" 애니메이션이 기본으로 들어 있다.
		frames.add_frame(&"default", d.texture)
		_static_frames[d.texture] = frames
	return _static_frames[d.texture]


static func _used_rect(tex: Texture2D) -> Rect2:
	if not _used_rect_cache.has(tex):
		var image := tex.get_image()
		_used_rect_cache[tex] = Rect2(image.get_used_rect()) if image != null else Rect2(Vector2.ZERO, tex.get_size())
	return _used_rect_cache[tex]
