extends QuadTreeObj

@export var score_label : Label
@export var score_timer : Timer

var is_dead = false
var move_speed = 170
var dash_distance = 100
var dead_distance = 20

var all_groups = ["Alpha","Beta","Player","Delta"]

@onready var animator = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

#在game中调用，传入四叉树，判断player附近小范围内是否有其他boid，返回布尔值
func is_player_dead(quadtree:QuadTree):
	var nearby_boids = []
	var nearby_range = Rect2(position - Vector2(dead_distance, dead_distance), Vector2(dead_distance * 2, dead_distance * 2))
	quadtree.query(nearby_range, nearby_boids)
	var that_is_my_predator = false
	for other in nearby_boids:
		that_is_my_predator = other.get_group_index() < self.get_group_index()
		if not that_is_my_predator:
			continue
		if self.position.distance_to(other.position) < dead_distance:
			is_dead = true
			return true
		else:
			return false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#定义初始向量方向
	var direction = Vector2.ZERO
	#检测输入
	if Input.is_action_pressed("move_right"):
		direction.x = 1
	if Input.is_action_pressed("move_left"):
		direction.x = -1
	if Input.is_action_pressed("move_up"):
		direction.y = -1
	if Input.is_action_pressed("move_down"):
		direction.y = 1
	
	#更改朝向
	if direction.length() > 0:
		rotation = lerp_angle(rotation, direction.angle(), PI*2*delta)
	
	#动画切换,以及冲刺
	if is_dead:
		animator.play("GameOver")
	elif direction == Vector2.ZERO:
		animator.play("Idle")
	elif Input.is_action_pressed("dash"):
		move_speed = 300
		animator.play("Dash")
	else:
		move_speed = 170
		animator.play("Swim")
		
	#更改位置
	if not is_dead:
		position += direction * delta * move_speed

# 剔除以下划线开头的Godot内部分组，返回此boid的ABC分组
func get_this_group():
	var non_internal_group :String
	for group in get_groups():
		if not str(group).begins_with("_"):
			non_internal_group = group
			break
	#测试代码 print(get_this_group()[0])
	return non_internal_group
	
func get_group_index():
	var index = 0
	for group in all_groups:
		if group == get_this_group():
			index = all_groups.find(group)
			break
	return index
