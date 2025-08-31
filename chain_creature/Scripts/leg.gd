class_name Leg
	
var root : Vector2  #与身体连接
var joint : Vector2 #关节
var joint2 : Vector2
var foot : Vector2
var step_lenth : float = 50 #每一步的长度
var miles : float = 0 #移动里程
var stage : Array = [0,0,0,0,0,0,0,0,0,0] #

func _init(root:Vector2,foot:Vector2) -> void:
	self.root = root
	self.foot = foot
	self.joint = (root+foot)/2 + Vector2(-(foot-root).y,(foot-root).x)*0.6

func foot_move(index:int,dir:Vector2): #index表示这是第几节，dir是这一节的运动方向
	
	#垂直运动方向
	var x_change = Vector2(-dir.y,dir.x) * 20  #垂直运动方向
	#平行运动方向，Engine函数得到全局物理时间，对其取模再作为stage数组的index，即让每个物理时间来按stage顺序报数
	var y_change = dir * step_lenth * stage[(index + int(miles)) % 10] 
	foot = root + x_change + y_change
	joint = (root+foot)/2 + Vector2(-(foot-root).y,(foot-root).x)*0.6
#func _following_foot_move(target:Leg): #后续的腿，以前一个腿为目标
#	pass
