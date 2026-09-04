extends CharacterBody2D

const ITEM_STACK_INSTANCE := preload("res://scenes/objects/pickables/item_stack_instance.tscn")

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

@export var min_range = 8
@export var max_range = 100

var walk_cycles: int
var current_walk_cycle: int

@export var knockback_speed: float = 120.0

var npc_direction: Vector2 = Vector2.DOWN
var is_dead: bool = false

var knockback: Vector2 = Vector2.ZERO


func _ready() -> void:
	# 여러 마리가 같은 .tres를 공유하므로 각자 사본을 들어야 한다.
	# duplicate()는 base_* 만 옮기므로 파생값은 setup_stats()가 채운다.
	stats = stats.duplicate()
	stats.setup_stats()

	hit_component.hit_damage = stats.current_attack
	hurt_component.hurt.connect(on_hurt)
	stats.health_depleted.connect(die)

	walk_cycles = randi_range(min_walk_cycle, max_walk_cycle)


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

	var loot := ITEM_STACK_INSTANCE.instantiate() as ItemStackInstance
	# add_child가 _ready를 돌리므로 그 전에 무엇인지 알려준다.
	loot.stack = ItemStack.new(loot_item, 1)
	host.add_child(loot)
	loot.global_position = global_position
