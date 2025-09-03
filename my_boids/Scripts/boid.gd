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
var D_boid_die_distance = 25

var separation_weight = 1.2 
var alignment_weight = 1.0
var cohesion_weight = 1.0
var trace_weight = 0.0 #追逐目标点
var avoid_weight = 20 #避障
var prey_weight = 1.0 #追逐猎物
var flee_weight = 2.5 #躲避天敌

var space_state: PhysicsDirectSpaceState2D  #用于避障，实现RayCast2D的功能

var all_groups = ["Alpha","Beta","Player","Delta"]

signal D_boid_die(emitter) #D boid死亡信号，参数为信号发出者，传递self
signal player_caught_D_boid() #玩家抓住D Boid的信号


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
	
#对齐：附近个体的平均速度，只看同种群
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
	
#聚集：附近个体的平均位置，只看同种群
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
	
#分离：远离附近个体，只看同种群
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

#追逐target
func _trace(): 
	if trace_target == null:
		return Vector2.ZERO
	return steer_towards(trace_target - position)	

#避障
func _avoid():  
	
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
	var that_is_my_prey = false
	for other in neighbors:
		that_is_my_prey = other.get_group_index() > self.get_group_index()
		if other == self or not that_is_my_prey:
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
	var that_is_my_predator = false
	for other in neighbors:
		that_is_my_predator = other.get_group_index() < self.get_group_index()
		if other == self or not that_is_my_predator: #目前只对Alpha有逃跑效果
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

#以当前速度方向为中心，反复左右偏移，return射线不碰撞障碍物的方向
func _calc_avoid_steer():  
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
	
#汇总所有方法
func apply_behaviors(delta: float, quadtree: QuadTree):
	var nearby_boids = []
	var nearby_range = Rect2(position - Vector2(prey_limit, prey_limit), Vector2(prey_limit * 2, prey_limit * 2))
	quadtree.query(nearby_range, nearby_boids)
	
	#各个方法对加速度的贡献
	var separation = _separate(nearby_boids) * separation_weight
	var alignment = _align(nearby_boids) * alignment_weight
	var cohesion = _cohere(nearby_boids) * cohesion_weight
	var trace = _trace() * trace_weight
	var avoid = _avoid() * avoid_weight
	var prey = _prey(nearby_boids) * prey_weight
	var flee = _flee(nearby_boids) * flee_weight
	
	var accelaration = separation + alignment + cohesion + trace + avoid + prey + flee
		
	
	if is_in_group("Alpha"):
		if prey !=  Vector2.ZERO:
			max_speed = 130
			$AnimatedSprite2D.play("chase")
		else:
			max_speed = 90
			$AnimatedSprite2D.play("wander")
		
	if is_in_group("Beta"):
		if flee != Vector2.ZERO:
			max_speed = 170
			$AnimatedSprite2D.play("flee")
		elif prey != Vector2.ZERO:
			max_speed = 170
			$AnimatedSprite2D.play("B_chase")
		else:
			max_speed = 120
			$AnimatedSprite2D.play("wander")
		
	if is_in_group("Delta"):
		#首先判断死没死
		var is_dead = false
		for other in nearby_boids:
			if other.get_group_index() < 3:  #是玩家或更大的鱼
				if self.position.distance_to(other.position) < D_boid_die_distance:
					if other.get_group_index() == 2:  #当且仅当是玩家抓的，才发信号
						player_caught_D_boid.emit()
					
					is_dead = true
					D_boid_die.emit(self)
					quadtree.remove(self)
					$AnimatedSprite2D.play("die")
					await get_tree().create_timer(0.1).timeout
					queue_free()
					break
					
		if not is_dead:
			if flee != Vector2.ZERO:
				max_speed = 170
				$AnimatedSprite2D.play("flee")
			else:
				max_speed = 150
				$AnimatedSprite2D.play("wander")
			accelaration -= avoid #Delta种群不用避障
		
	velocity += accelaration
	velocity = velocity.limit_length(max_speed)
	position += velocity * delta
	if velocity.length() > 0:
		rotation = lerp_angle(rotation, velocity.angle(), PI*delta)
	
	wrap_screen()
	quadtree.remove(self)
	quadtree.insert(self)

func wrap_screen():  #贪吃蛇同款，移出屏幕改为穿越至另一侧
	
	position.x = wrapf(position.x, 0, screen_size.x)
	position.y = wrapf(position.y, 0, screen_size.y)
	
func set_target(target):
	trace_target = target
