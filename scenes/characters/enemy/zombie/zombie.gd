extends CharacterBody2D

const DROPPED_ITEM := preload("res://scenes/objects/pickables/dropped_item.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurt_component: HurtComponent = $HurtComponent
@onready var damage_component: DamageComponent = $DamageComponent
@onready var die_audio_stream_player: AudioStreamPlayer2D = $DieAudioStreamPlayer
@onready var hit_component: HitComponent = $HitComponent
@onready var state_machine: NodeStateMachine = $StateMachine
@onready var root_table: Node = $RootTable

@export var stats: BaseCharacterStats

@export var min_walk_cycle: int = 2
@export var max_walk_cycle: int = 6

## 이 거리 안으로 붙으면 chase 가 attack 으로 넘긴다.
@export var attack_range: float = 20.0
## 한 번 휘두르고 다음 휘두르기까지 쉬는 시간.
@export var attack_cooldown: float = 1.2

var walk_cycles: int
var current_walk_cycle: int

@export var knockback_speed: float = 120.0

var npc_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false

var knockback: Vector2 = Vector2.ZERO

var attack_ready: bool = true

@onready var attack_cooldown_timer: Timer = Timer.new()


func _ready() -> void:
	# 여러 마리가 같은 .tres를 공유하므로 각자 사본을 들어야 한다.
	# duplicate()는 base_* 만 옮기므로 파생값은 setup_stats()가 채운다.
	stats = stats.duplicate()
	stats.setup_stats()

	hit_component.hit_damage = stats.current_attack
	hurt_component.hurt.connect(on_hurt)
	stats.health_depleted.connect(die)

	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)

	attack_cooldown_timer.one_shot = true
	attack_cooldown_timer.timeout.connect(on_attack_cooldown_timeout)
	add_child(attack_cooldown_timer)


## 8방향 벡터를 상하좌우 4방향 애니메이션으로 뭉갠다. 성분이 큰 축을 따른다.
func face_towards(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	if absf(direction.x) > absf(direction.y):
		npc_direction = Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	else:
		npc_direction = Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func start_attack_cooldown() -> void:
	attack_ready = false
	attack_cooldown_timer.start(attack_cooldown)


func on_attack_cooldown_timeout() -> void:
	attack_ready = true


func on_hurt(hit_damage: int) -> void:
	stats.health -= hit_damage

	if is_dead:
		return

	knockback = hurt_component.last_knockback_direction * knockback_speed
	state_machine.transition_to("hit")


func die() -> void:
	is_dead = true

	state_machine.set_process(false)
	state_machine.set_physics_process(false)
	velocity = Vector2.ZERO

	hurt_component.set_deferred("monitoring", false)
	hit_component.set_deferred("monitoring", false)
	set_deferred("collision_layer", 0)

	animated_sprite_2d.flip_h = false
	animated_sprite_2d.play("die")
	die_audio_stream_player.play()

	await animated_sprite_2d.animation_finished
	if die_audio_stream_player.playing:
		await die_audio_stream_player.finished

	drop_loot.call_deferred()
	queue_free()


func drop_loot() -> void:
	var loot_item: Item = root_table.roll()
	if loot_item == null:
		return

	var host := get_parent()
	if host == null:
		return

	var loot := DROPPED_ITEM.instantiate() as Node2D
	# add_child가 _ready를 돌리므로 그 전에 무엇인지 알려준다.
	loot.item = loot_item
	host.add_child(loot)
	loot.global_position = global_position
