class_name HurtComponent
extends Area2D

## 도구별 타격음. 스트림 표는 AudioManager 하나만 두고 여기선 키만 가리킨다.
## 여기 없는 도구(Melee, None)는 씬에 박힌 HitAudioStreamPlayer 의 소리를 그대로 쓴다.
const TOOL_SFX: Dictionary = {
	DataTypes.Tools.AxeWood: AudioManager.SFX_TREE_HITTING,
	DataTypes.Tools.MineRock: AudioManager.SFX_MINING_ROCK,
	DataTypes.Tools.TillGround: AudioManager.SFX_TILLING_GROUND,
	DataTypes.Tools.WaterCrops: AudioManager.SFX_WATERING_CROPS,
	# TODO: 심는 소리가 아직 없다. 흙 소리로 임시로 때운다.
	DataTypes.Tools.PlantPotato: AudioManager.SFX_TILLING_GROUND,
	DataTypes.Tools.PlantWheat: AudioManager.SFX_TILLING_GROUND,
	DataTypes.Tools.PlantCorn: AudioManager.SFX_TILLING_GROUND,
}

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hit_audio_stream_player: AudioStreamPlayer2D = $HitAudioStreamPlayer
@export var tool: DataTypes.Tools = DataTypes.Tools.None
@export var stats: BaseCharacterStats

signal hurt(hit_damage: int)

var last_knockback_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	animated_sprite_2d.visible = false
	animated_sprite_2d.animation_finished.connect(on_hit_effect_finished)

	# tool 은 인스턴스마다 고정이라 소리도 여기서 한 번만 정하면 된다.
	# 표에 없는 도구(Melee, None)면 손대지 않는다 — 씬에 꽂힌 소리가 그대로 남는다.
	var sound := tool_hit_sound()
	if sound != null:
		hit_audio_stream_player.stream = sound


func _on_area_entered(area: Area2D) -> void:
	var hit_component = area as HitComponent
	
	if hit_component.owner == owner:
		return

	if hit_component == null:
		return

	if tool == hit_component.current_tool:
		play_hit_effect()
		last_knockback_direction = get_knockback_direction(hit_component)
		hurt.emit(hit_component.hit_damage)

func get_knockback_direction(hit_component: HitComponent) -> Vector2:
	if hit_component.knockback_vector != Vector2.ZERO:
		return hit_component.knockback_vector.normalized()

	return hit_component.global_position.direction_to(global_position)

func play_hit_effect() -> void:
	animated_sprite_2d.visible = true
	animated_sprite_2d.frame = 0
	animated_sprite_2d.play("default")
	# 전역 풀(SignalBus.sound_requested)이 아니라 이 2D 플레이어로 낸다.
	# 맞은 물체 자리에서 나야 거리감이 생긴다.
	hit_audio_stream_player.play()

func tool_hit_sound() -> AudioStream:
	if not TOOL_SFX.has(tool):
		return null

	return AudioManager.SOUND_EFFECTS.get(TOOL_SFX[tool])


func on_hit_effect_finished() -> void:
	animated_sprite_2d.visible = false
	
