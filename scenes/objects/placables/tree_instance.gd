class_name TreeInstance
extends ObjectInstance

var tree: TreeObject:
	get:
		return object as TreeObject

@export var stage: int = 0


func _ready() -> void:
	super()
	_refresh_stage()


func is_mature() -> bool:
	return tree == null or stage >= tree.max_stage()


## 하루치 성장. 언제 부를지는 FarmSpawner 가 정한다 — 농장을 비운 사이 지난
## 날짜까지 몰아서 돌려야 해서 time_tick_day 를 직접 받지 않는다.
func day_update() -> void:
	if tree == null or is_mature():
		return

	if randf() < tree.grow_chance:
		stage += 1
		_refresh_stage()


func on_hurt(hit_damage: int) -> void:
	if is_mature():
		super(hit_damage)
		return

	current_health -= hit_damage
	if current_health > 0:
		play_shake()
		return

	queue_free()


func capture_state() -> Variant:
	return {"stage": stage}


func apply_state(state: Variant) -> void:
	if state is not Dictionary:
		return

	stage = int(state.get("stage", stage))
	_refresh_stage()


func _refresh() -> void:
	super()
	if is_node_ready():
		_refresh_stage()


func _refresh_stage() -> void:
	if tree == null or tree.growth_textures.is_empty():
		return

	stage = clampi(stage, 0, tree.max_stage())
	var next := tree.growth_textures[stage]
	if next == null:
		return

	texture = next
	centered = false
	var size := next.get_size()
	offset = Vector2(-size.x * 0.5, -size.y)

	if is_mature():
		current_health = tree.object_max_health
		_refresh_hurtbox()
		_refresh_body()
		body_shape.disabled = false
	else:
		current_health = tree.sapling_health
		var circle := CircleShape2D.new()
		circle.radius = minf(float(tree.hurtbox_radius), size.y * 0.5)
		hurtbox_shape.shape = circle
		hurtbox_shape.position = Vector2(0, -size.y * 0.5)
		body_shape.disabled = true

	_refresh_shake()
