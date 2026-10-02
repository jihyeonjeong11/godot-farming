class_name RpgmCharacter
extends CharacterBody2D

const DIR := "res://assets/temp/rpgm_character/"
const CELL := 64
const ANIMS := {
	"idle": {speed = 8.0, loop = true},
	"walk": {speed = 10.0, loop = true},
	"attack": {speed = 12.0, loop = false},
}
const VIEWS := ["down", "side", "up"]
const SHEET_ROWS := {"side": 0, "down": 1, "up": 2}
const SHEET_COLS := {"idle": [0], "walk": [1, 2, 3, 4, 5, 6], "attack": [7, 8, 9]}
const OUTFIT_PARTS := ["Hair", "Shirt", "Pants", "Shoes"]
const DRAW_ORDER := ["Pants", "Shoes", "Shirt", "Bag", "Hair"]

@export var speed := 60.0
@export var is_freeze := false
@export var body_sheet: Texture2D
@export var shadow_sheet: Texture2D
@export var hair_sheets: Array[Texture2D] = []
@export var shirt_sheets: Array[Texture2D] = []
@export var pants_sheets: Array[Texture2D] = []
@export var shoes_sheets: Array[Texture2D] = []
@export var bag_sheet: Texture2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var shadow: AnimatedSprite2D = get_node_or_null("Shadow")
@onready var info: Label = get_node_or_null("../CanvasLayer/Info")

var facing := "down"
var parts: Array[AnimatedSprite2D] = []
var layers := {}
var _frames_cache := {}
var attacking := false


func _ready() -> void:
	sprite.sprite_frames = _sheet_frames(body_sheet) if body_sheet else _build_frames()
	if shadow:
		shadow.visible = shadow_sheet != null
		if shadow_sheet:
			shadow.sprite_frames = _sheet_frames(shadow_sheet)
			sprite.frame_changed.connect(func() -> void: shadow.frame = sprite.frame)
	for layer_name in DRAW_ORDER:
		var part := AnimatedSprite2D.new()
		part.name = layer_name
		part.offset = sprite.offset
		part.visible = false
		add_child(part)
		parts.append(part)
		layers[layer_name] = part
	if bag_sheet:
		_wear(layers["Bag"], bag_sheet)
	if body_sheet:
		for part in OUTFIT_PARTS.size():
			equip(part, Inventory.get_vanity(part))
	sprite.frame_changed.connect(_sync_parts)
	sprite.animation_finished.connect(func() -> void: attacking = false)
	_play("idle")


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for view in VIEWS:
		for act in ANIMS:
			var tex := load("%s_%s %s.png" % [DIR, view, act]) as Texture2D
			var anim := StringName("%s_%s" % [act, view])
			frames.add_animation(anim)
			frames.set_animation_speed(anim, ANIMS[act].speed)
			frames.set_animation_loop(anim, ANIMS[act].loop)
			var img := tex.get_image()
			for y in tex.get_height() / CELL:
				for x in tex.get_width() / CELL:
					var rect := Rect2i(x * CELL, y * CELL, CELL, CELL)
					if img.get_region(rect).is_invisible():
						continue
					var atlas := AtlasTexture.new()
					atlas.atlas = tex
					atlas.region = rect
					frames.add_frame(anim, atlas)
	return frames


func _sheet_frames(sheet: Texture2D) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for view in VIEWS:
		for act in ANIMS:
			var anim := StringName("%s_%s" % [act, view])
			frames.add_animation(anim)
			frames.set_animation_speed(anim, ANIMS[act].speed)
			frames.set_animation_loop(anim, ANIMS[act].loop)
			for col in SHEET_COLS[act]:
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2i(col * CELL, SHEET_ROWS[view] * CELL, CELL, CELL)
				frames.add_frame(anim, atlas)
	return frames


func outfit_count(part: int) -> int:
	return _outfit_sheets(part).size()


func equip(part: int, index: int) -> void:
	var sheets := _outfit_sheets(part)
	var layer: AnimatedSprite2D = layers[OUTFIT_PARTS[part]]
	if index >= 0 and index < sheets.size():
		_wear(layer, sheets[index])
	else:
		index = -1
		layer.visible = false
	Inventory.set_vanity(part, index)


func _outfit_sheets(part: int) -> Array[Texture2D]:
	return [hair_sheets, shirt_sheets, pants_sheets, shoes_sheets][part]


func _wear(layer: AnimatedSprite2D, sheet: Texture2D) -> void:
	if not _frames_cache.has(sheet):
		_frames_cache[sheet] = _sheet_frames(sheet)
	layer.sprite_frames = _frames_cache[sheet]
	layer.visible = true
	_sync_parts()


func _sync_parts() -> void:
	for part in parts:
		if not part.visible or not part.sprite_frames.has_animation(sprite.animation):
			continue
		part.flip_h = sprite.flip_h
		part.animation = sprite.animation
		part.frame = sprite.frame


func _physics_process(_delta: float) -> void:
	if attacking:
		return
	if is_freeze:
		_play("idle")
		return
	if Input.is_action_just_pressed("hit"):
		attacking = true
		_play("attack")
		return
	var input := Input.get_vector("walk_left", "walk_right", "walk_up", "walk_down")
	if input != Vector2.ZERO:
		if absf(input.x) >= absf(input.y):
			facing = "right" if input.x > 0.0 else "left"
		else:
			facing = "down" if input.y > 0.0 else "up"
	velocity = input * speed
	move_and_slide()
	_play("walk" if input != Vector2.ZERO else "idle")


func _play(act: String) -> void:
	var view := "side" if facing in ["left", "right"] else facing
	sprite.flip_h = facing == "right"
	var anim := StringName("%s_%s" % [act, view])
	if sprite.animation != anim or not sprite.is_playing():
		sprite.play(anim)
		if shadow and shadow.visible:
			shadow.flip_h = sprite.flip_h
			shadow.animation = anim
			shadow.frame = sprite.frame
		_sync_parts()
	if info:
		info.text = "%s  frame %d/%d  (방향키 이동, 클릭 공격)" % [anim, sprite.frame + 1, sprite.sprite_frames.get_frame_count(anim)]
