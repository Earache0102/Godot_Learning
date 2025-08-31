extends Node2D

var chain:Chain        # 链
var target:Vector2     # 记录鼠标位置
var points:PackedVector2Array = [
	Vector2(0,0),
	Vector2(50,0),
	Vector2(100,0),
	Vector2(150,0),
	Vector2(250,0),
]
var legs : Array = []  #所有leg的数组
var dis = 20
var radius = 10
var total_number = 20

func _ready() -> void:
	
	chain = CircleChain.new(dis,radius,total_number)
	points = chain.points
	var root : Vector2
	var foot : Vector2
	var this_leg : Leg
	for i in range(total_number):
		root = points[i] + Vector2(0,radius)
		foot = points[i] + Vector2(0,radius * 2)
		this_leg = Leg.new(root,foot)
		legs.append(this_leg)

func _physics_process(delta: float) -> void:
	target = get_global_mouse_position()
	chain.update_points_fk(target,chain.state_manager.current_state) # 根据鼠标位置，移动链
	miles_update()
	
	#移动脚
	var dir = points[0].direction_to(target)
	legs[0].root = points[0] + Vector2(-dir.y,dir.x) * radius
	legs[0].foot_move(0,dir)
	for i in range(1,total_number):
		target = points[i-1]
		dir = points[i].direction_to(points[i-1])
		legs[i].root = points[i] + Vector2(-dir.y,dir.x) * radius
		legs[i].foot_move(i,dir)
	queue_redraw()

func _draw() -> void:
	draw_polyline(chain.points,Color.WHITE,1)
	for p in chain.points:
		draw_circle(p,3,Color.AQUAMARINE)
	chain.draw_circles(self)
	#对于数组points做for循环，给每一节画腿
	var r : Vector2
	var j : Vector2
	var f : Vector2
	for i in range(total_number):
		draw_polyline([legs[i].root,legs[i].joint,legs[i].foot],Color.WHITE,1)
		r = 2 * chain.points[i] - legs[i].root
		f = 2 * chain.points[i] - legs[i].foot
		j = (r+f)/2 - Vector2(-(f-r).y,(f-r).x)*0.6
		draw_polyline([r,j,f],Color.WHITE,1)

func miles_update():
	chain.miles = chain.move_speed * Time.get_ticks_usec()
	for i in legs:
		i.miles = chain.miles
	
	
	
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
		# 计算出初始的位置值
		for i in range(total_number):
			points.append(Vector2(-dis,0) * i)   # 沿X轴方向向左排列
	# 绘制圆
	func draw_circles(canvas:CanvasItem,color:=Color.WHITE,fill:=false,border_width:=1.0) -> void:
		for i in range(points.size()):
			canvas.draw_circle(points[i],radius,color,fill,border_width)
