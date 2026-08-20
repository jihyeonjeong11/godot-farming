class_name Player
extends CharacterBody2D

const TEST_KEYS := {
	"run": KEY_SHIFT,
	"jump": KEY_SPACE,
	"sit": KEY_C,
	"emote": KEY_F,
	"climb": KEY_X,
	"hurt": KEY_H,
}

const TOOL_ACTION := {
	"hoe": "thrust",
	"shovel": "thrust",
	"watering_can": "thrust",
	"axe": "tool_axe",
	"pickaxe": "tool_axe",
	"hammer": "tool_hammer",
	"fishing_rod": "tool_rod",
	"whip": "tool_whip",
}

const TOOL_VISIBLE_ACTIONS: Array[String] = [
	"thrust",
	"tool_axe",
	"tool_hammer",
	"tool_rod",
	"tool_whip",
	"slash",
]

const BARE_REACH := 18.0
const BARE_RADIUS := 14.0
const TOOL_FRAMES_DIR := "res://scenes/characters/player/tools/"

@export var sprite_layers: Array[AnimatedSprite2D] = []

@export var tool_back_sprite: AnimatedSprite2D
@export var tool_front_sprite: AnimatedSprite2D
@export var state_machine: NodeStateMachine
@export var direction_component: CharacterDirectionComponent
@export var walk_speed: int = 90
@export var run_speed: int = 150

@export var stats: Stats

@onready var hit_component: HitComponent = $HitComponent
@onready var hit_shape: CollisionShape2D = $HitComponent/HitComponentShape2D

var _equipped_item: Items
var equipped_tool: String = ""

var _held: Dictionary = {}
var _just_pressed: Dictionary = {}

var _drawn_tool: String = ""

var _current_action: String = "idle"
var _current_duration: float = 0.0
var _tool_frames_cache: Dictionary = {}

func _unhandled_input(event: InputEvent) -> void:
	var slot := GameInputEvents.number_key_input(event)
	if slot >= 0:
		Inventory.select_slot(slot)
		get_viewport().set_input_as_handled()



func _ready() -> void:
	Inventory.set_player_reference(self)
	apply_hitbox(null)

func apply_hitbox(item: Items) -> void:
	if hit_shape == null:
		return

	if item != null and item.melee_shape != null:
		hit_shape.shape = item.melee_shape.duplicate() as Shape2D
		return

func _physics_process(_delta: float) -> void:
	for key in TEST_KEYS:
		_edge(key, TEST_KEYS[key])

	if _just_pressed["hurt"]:
		take_hit()

	if GameInputEvents.interact():
		print('좌표', global_position, get_global_mouse_position())
		# 타일과 인터렉트 할 케이스가 있을까? 확인 필요.
		# 오브젝트 레이어와 인터렉트 침대, 작물 수확, 상자 같은건 오브젝트 레이어로 소통.
		# 먼저 objectCursorComponent를 만들고 생각하자.
		
		SignalBus.interact_handled = false
		SignalBus.interact_used.emit(global_position, get_global_mouse_position())

		if not SignalBus.interact_handled:
			consume_selected()

	var held: Items = Inventory.get_selected_item()
	equipped_tool = String(held.anim_prefix) if held != null else ""

	hit_component.current_tool = held.tool_type if held != null else DataTypes.Tools.None
	hit_component.hit_damage = held.melee_damage if held != null else 0

	if held != _equipped_item:
		_equipped_item = held
		apply_hitbox(held)

	var facing := direction_component.get_facing()
	hit_shape.position = facing * (held.melee_reach if held != null else BARE_REACH)
	hit_shape.rotation = facing.angle()

	if equipped_tool != _drawn_tool:
		_drawn_tool = equipped_tool
		apply_tool_frames()

func _edge(key: String, code: Key) -> bool:
	var down: bool = Input.is_physical_key_pressed(code)
	var edge: bool = down and not _held.get(key, false)
	_held[key] = down
	_just_pressed[key] = edge
	return edge

func attack_action() -> String:
	return TOOL_ACTION.get(equipped_tool, "slash")

func set_hitbox_active(active: bool) -> void:
	if hit_shape != null:
		hit_shape.set_deferred("disabled", not active)

func has_melee_shape() -> bool:
	var item: Items = Inventory.get_selected_item()
	return item != null and item.melee_shape != null

func can_attack() -> bool:
	var item: Items = Inventory.get_selected_item()
	# 씨앗도 통과시킨다. 심기는 히트박스가 아니라 타일 통로(crops_cursor_component)로 가므로
	# melee_shape가 없는 게 정상이고, 여기서 막으면 tool_used 자체가 안 나간다.
	if item != null and (item.item_type == "tool" or item.item_type == "seeds"):
		return true
	return item != null and item.melee_shape != null

func consume_selected() -> bool:
	var item: Items = Inventory.get_selected_item()
	if item == null or item.item_type != "consumable":
		return false

	if item.edible > 0 and stats != null:
		stats.health = mini(stats.health + item.edible, stats.max_health)

	Inventory.remove_item(Inventory.selected_slot, 1)
	return true

func finish_tool_use() -> void:
	var item: Items = Inventory.get_selected_item()
	if item == null:
		return
	SignalBus.tool_used.emit(item, global_position, get_global_mouse_position())

func key_just_pressed(key: String) -> bool:
	return _just_pressed.get(key, false)

func key_held(key: String) -> bool:
	return _held.get(key, false)

func play_action(action: String, duration: float = 0.0) -> void:
	_current_action = action
	_current_duration = duration
	
	var directional := "%s_%s" % [action, direction_component.get_suffix()]
	var speed := 1.0
	if duration > 0.0:
		var length := clip_length(directional)
		if length > 0.0:
			speed = length / duration

	for layer in sprite_layers:
		layer.speed_scale = speed

	var show_tool := TOOL_VISIBLE_ACTIONS.has(action)
	

	for layer in sprite_layers:
		var frames := layer.sprite_frames
		var clip := ""
		if frames != null:
			if frames.has_animation(directional):
				clip = directional
			elif frames.has_animation(action):
				clip = action

		if not show_tool and is_tool_layer(layer):
			clip = ""

		layer.visible = not clip.is_empty()
		if clip.is_empty():
			layer.stop()
		else:
			layer.play(clip)


func is_tool_layer(layer: AnimatedSprite2D) -> bool:
	return layer == tool_back_sprite or layer == tool_front_sprite

func clip_length(clip: StringName) -> float:
	if sprite_layers.is_empty():
		return 0.0

	var frames := sprite_layers[0].sprite_frames
	if frames == null or not frames.has_animation(clip):
		return 0.0

	var count := frames.get_frame_count(clip)
	var fps := frames.get_animation_speed(clip)
	if count <= 0 or fps <= 0.0:
		return 0.0

	return count / fps


func stop_action() -> void:
	for layer in sprite_layers:
		layer.stop()

func apply_tool_frames() -> void:
	if tool_back_sprite != null:
		tool_back_sprite.sprite_frames = load_tool_frames("bg")
	if tool_front_sprite != null:
		tool_front_sprite.sprite_frames = load_tool_frames("fg")

	play_action(_current_action, _current_duration)


func load_tool_frames(suffix: String) -> SpriteFrames:
	if equipped_tool.is_empty():
		return null

	var key := "%s_%s" % [equipped_tool, suffix]
	if _tool_frames_cache.has(key):
		return _tool_frames_cache[key]

	var path := "%s%s.tres" % [TOOL_FRAMES_DIR, key]
	var frames: SpriteFrames = null
	if ResourceLoader.exists(path):
		frames = load(path) as SpriteFrames
	else:
		push_warning("툴 스프라이트가 없습니다: %s" % path)

	_tool_frames_cache[key] = frames
	return frames

func is_action_playing() -> bool:
	return not sprite_layers.is_empty() and sprite_layers[0].is_playing()

func take_hit(_hit_damage: int = 0) -> void:
	if state_machine:
		state_machine.transition_to("Hurt")
