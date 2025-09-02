extends QuadTreeObj
class_name Boid

var screen_size = Vector2(1593, 896)

var velocity = Vector2.ZERO
var max_speed = 200
var max_force = 10

var trace_target: Vector2

var perception_radius = 50 #同种群内的影响半径
var separation_limit = 40 #分离的影响半径
var prey_limit = 100 #关于天敌与猎物的影响半径，作为四叉树查询半径

var separation_weight = 1.2 
var alignment_weight = 0.9
var cohesion_weight = 0.9
var trace_weight = 0.0 #追逐目标点
var avoid_weight = 20 #避障
var prey_weight = 2.0 #追逐猎物
var flee_weight = 5.0 #躲避天敌

var space_state: PhysicsDirectSpaceState2D  #用于避障，实现RayCast2D的功能

# 剔除以下划线开头的Godot内部分组，返回此boid的ABC分组
func get_this_group():
	var non_internal_groups = []
	for group in get_groups():
		if not str(group).begins_with("_"):
			non_internal_groups.push_back(group)
	#测试代码 print(get_this_group()[0])
	return non_internal_groups[0]

func _ready() -> void:
	velocity = Vector2(randf() * max_speed, randf() * max_speed)
	rotation = velocity.angle()
	space_state = get_world_2d().direct_space_state
	
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
#传入目标速度向量，目标速度向量 - 当前速度向量 = 速度的变化量，得到加速度向量
func steer_towards(sum: Vector2):
	var steer = sum.normalized() * max_speed - velocity
	return steer.limit_length(max_force)
	
#对齐：附近个体的平均速度
func _align(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self or not other.is_in_group(get_this_group()):
			continue
		var distance = position.distance_to(other.position)
		if distance > 0 and distance < perception_radius:
			sum += other.velocity
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum)
	
	return sum
	
#聚集：附近个体的平均位置
func _cohere(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self or not other.is_in_group(get_this_group()):
			continue
		var distance = position.distance_to(other.position)
		if distance > 0 and distance < perception_radius:
			sum += other.position
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum - position)
	
	return sum
	
#分离：远离附近个体
func _separate(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self or not other.is_in_group(get_this_group()):
			continue
		var distance = position.distance_to(other.position)
		if distance > 0 and distance < separation_limit:
			var diff = (position - other.position).normalized()
			diff /= distance  #距离越近，分离趋势越强
			sum += diff
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum)
	
	return sum

func _trace(): #追逐target
	if trace_target == null:
		return Vector2.ZERO
	return steer_towards(trace_target - position)	

func _avoid():  #避障
	
	var steer = Vector2.ZERO
	var query = PhysicsRayQueryParameters2D.create(global_position, global_position + velocity.normalized() * 150)
	var result = space_state.intersect_ray(query)
	
	if result.size():
		#计算绕开的角度
		var dir = _calc_avoid_steer()
		steer = steer_towards(dir)
	
	return steer

#追逐前方的猎物
func _prey(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self or other.is_in_group(get_this_group()) or other.is_in_group("Alpha"):
			continue
		var distance = position.distance_to(other.position)
		
		#dot内积，内积大于0说明猎物在前方
		if distance > 0 and distance < prey_limit and (other.position - position).dot(velocity) > 0: 
			var diff = (other.position - position).normalized() #减的方向反过来，从分离改成靠近
			diff /= distance  #距离越近，靠近趋势越强
			sum += diff
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum)
		
	return sum

#躲避天敌
func _flee(neighbors):
	var sum = Vector2.ZERO
	var count = 0
	for other in neighbors:
		if other == self or not other.is_in_group("Alpha"): #目前只对Alpha有逃跑效果
			continue
		var distance = position.distance_to(other.position)
		
		if distance > 0 and distance < prey_limit : 
			var diff = (position - other.position).normalized()
			diff /= distance  #距离越近，逃离趋势越强
			sum += diff
			count += 1
	if count > 0:
		sum /= count
		sum = steer_towards(sum)
		
	return sum

func _calc_avoid_steer():  #以当前速度方向为中心，反复左右偏移，return射线不碰撞障碍物的方向
	var current_direction = velocity.normalized()
	var best_direction = current_direction
	var found = false
	var max_attempts = 10
	for i in range(max_attempts/2):
		for j in range(2):
			var d = 1 if j == 0 else -1   #左右偏移各1次
			var angle_offset = deg_to_rad(10 * d * i)  #偏移改变的角度
			var direction = current_direction.rotated(angle_offset)  #偏移后的射线的角度
			var query = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * 150)#试探射线
			var result = space_state.intersect_ray(query) #存储试探射线的碰撞
			
			if result.size() == 0:
				best_direction = direction
				found = true
				break
	
	if found:
		return best_direction
	else:
		return current_direction
	
func apply_behaviors(delta: float, quadtree: QuadTree):
	var nearby_boids = []
	var nearby_range = Rect2(position - Vector2(prey_limit, prey_limit), Vector2(prey_limit * 2, prey_limit * 2))
	quadtree.query(nearby_range, nearby_boids)
	
	var separation = _separate(nearby_boids) * separation_weight
	var alignment = _align(nearby_boids) * alignment_weight
	var cohesion = _cohere(nearby_boids) * cohesion_weight
	var trace = _trace() * trace_weight
	var avoid = _avoid() * avoid_weight
	var prey = _prey(nearby_boids) * prey_weight
	
	var accelaration = separation + alignment + cohesion + trace + avoid + prey
		
	
	if is_in_group("Alpha"):
		if prey !=  Vector2.ZERO:
			max_speed = 150
			$AnimatedSprite2D.play("chase")
		else:
			max_speed = 100
			$AnimatedSprite2D.play("wander")
		
	#Beta种群有逃离天敌功能
	if is_in_group("Beta"):
		var flee = _flee(nearby_boids) * flee_weight
		if flee != Vector2.ZERO:
			max_speed = 275
			$AnimatedSprite2D.play("flee")
		elif prey != Vector2.ZERO:
			max_speed = 200
			$AnimatedSprite2D.play("B_chase")
		else:
			max_speed = 150
			$AnimatedSprite2D.play("wander")
		accelaration += flee
		
	velocity += accelaration
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta
	if velocity.length() > 0:
		rotation = lerp_angle(rotation, velocity.angle(), PI/2*delta)
	
	wrap_screen()
	quadtree.remove(self)
	quadtree.insert(self)

func wrap_screen():  #贪吃蛇同款，移出屏幕改为穿越至另一侧
	
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
func set_target(target):
	trace_target = target
