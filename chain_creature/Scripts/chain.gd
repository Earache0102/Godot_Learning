extends Node2D
class_name Chain

var points:PackedVector2Array   # 顶点数据
var lens:PackedFloat32Array     # 保存所有的初始距离
var move_speed : float = 4
var directions : Array
#State相关变量
var state_manager : State_Manager
var hunger : float = 10
var fear : float = 10

func _init(points:PackedVector2Array) -> void:
	self.points = points     # 记录初始顶点数据
	#State_Manager设置
	var state_manager = State_Manager.new(self)
	get_tree().current_scene.add_child(state_manager)
	self.state_manager = state_manager
	
	# 计算和记录每个初始顶点之间的距离并存储到 lens 数组中，并存储directions
	if points.size()>1:  
		directions[0] = points[1].direction_to(points[0])
		for i in range(points.size()-1):
			var p1 = points[i]
			var p2 = points[i+1]
			lens.append(p1.distance_to(p2))
			directions.append(points[i+1].direction_to(points[i]))

# 正向动力学 - 遍历定顶点，更新位置
func update_points_fk(target:Vector2,state:State) -> void:
	if points[0].distance_to(target) > 160:
		move_speed = 4
	else:
		move_speed = points[0].distance_to(target)/40
		
	points[0] += points[0].direction_to(target) * move_speed
	target = points[0]
	for i in range(1,points.size()):
		var dir = points[i].direction_to(target)   # 方向
		points[i] = target - lens[i-1] * dir
		target = points[i]
		
func update_mental():
	hunger += 1
	#fear = points[0].distance_to()
