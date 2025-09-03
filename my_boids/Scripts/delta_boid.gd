extends Boid
class_name DeltaBoid

@export var min_jump_delay: float = 0.3
@export var max_jump_delay: float = 1.3
@export var jump_cooldown: float = 0.3  # 跳跃后的冷却时间

@onready var jump_timer = $JumpTimer
@onready var cooldown_timer = $CooldownTimer

enum FishState { IDLE, CHASED, JUMPING, COOLDOWN }
var current_state: FishState = FishState.IDLE

func _ready():
	add_to_group("Delta")
	perception_radius = 50
	separation_limit = 30
	prey_limit = 130
	
	velocity = Vector2(randf() * max_speed, randf() * max_speed)
	rotation = velocity.angle()
	space_state = get_world_2d().direct_space_state
	
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func D_boid_is_caught():
	return false
