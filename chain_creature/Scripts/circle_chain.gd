class CircleChain extends Chain:

	var dis:float:                  # 固定间隔
		set(val):
			dis = val

	var radius:float:  # 圆形半径数列
		set(val):
			radius = val
			
	var total_number:int:
		set(val):
			total_number = val
			# 根据总节数，填充lens数组
			lens.resize(total_number)
			lens.fill(dis)
			
	var miles : float #移动里程
	var legs : Array

	func _init(dis:float,radius:float,total_number:int) -> void:
		self.dis = dis         # 记录固定间隔
		self.radius = radius   # 记录圆的半径
		self.total_number = total_number
		#State_Manager设置
		var state_manager = State_Manager.new(self)
		get_tree().current_scene.add_child(state_manager)
		self.state_manager = state_manager
		# 计算出初始的位置值
		for i in range(total_number):
			points.append(Vector2(-dis,0) * i)   # 沿X轴方向向左排列
	# 绘制圆
	func draw_circles(canvas:CanvasItem,color:=Color.WHITE,fill:=false,border_width:=1.0) -> void:
		for i in range(points.size()):
			canvas.draw_circle(points[i],radius,color,fill,border_width)
