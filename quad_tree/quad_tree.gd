extends Node
class_name QuadTree

const MAX_DEPTH = 3

#四叉树中储存的变量类型
#class_name QuadTreeObj extends Node2D:
#	pass
	
var boundry :Rect2 #四叉树管理的区间
var capacity : int #当前节点的储存容量
var objs : Array[QuadTreeObj] #当前节点的储存对象
var depth : int #当前节点的深度
var divided : bool #当前节点是否被分割，有且仅有叶子节点是未被分割的节点
var northeast : QuadTree
var northwest : QuadTree
var southeast : QuadTree
var southwest : QuadTree

func _init(_boundry : Rect2, _capacity : int, _depth : int = 1) -> void:
	boundry = _boundry
	capacity = _capacity
	objs = []
	divided = false
	depth = _depth
	
#分割方法
func _subdivide():
	var x = boundry.position.x
	var y = boundry.position.y
	var w = boundry.size.x / 2
	var h = boundry.size.y / 2
	var sub_depth = depth + 1
	
	var ne = Rect2(Vector2(x + w,y), Vector2(w,h))
	northeast = QuadTree.new(ne,capacity, sub_depth)
	
	var nw = Rect2(Vector2(x,y), Vector2(w,h))
	northwest = QuadTree.new(nw,capacity, sub_depth)
	
	var se = Rect2(Vector2(x + w,y + h), Vector2(w,h))
	southeast = QuadTree.new(se,capacity, sub_depth)
	
	var sw = Rect2(Vector2(x ,y + h), Vector2(w,h))
	southwest = QuadTree.new(sw,capacity, sub_depth)
	
	divided = true
	
#插入对象
func insert(obj : QuadTreeObj):
	if not boundry.has_point(obj.position):
		return false
		
	if objs.size() < capacity or depth == MAX_DEPTH:
		objs.append(obj)
		return true
	else:
		if not divided:
			_subdivide()
		if northeast.insert(obj):
			return true
		elif northwest.insert(obj):
			return true
		elif southeast.insert(obj):
			return true
		elif southwest.insert(obj):
			return true
			
	return false
	
#移除对象
func remove(obj):
	if obj in objs:
		objs.erase(obj)
		merge()
		return true
	
	if divided:
		if northeast.remove(obj):
			return true
		if northwest.remove(obj):
			return true
		if southeast.remove(obj):
			return true
		if southwest.remove(obj):
			return true
			
	return false
	
#查询范围的对象
func query( query_range : Rect2, found_objs:Array):
	if not boundry.intersects(query_range):
		return
		
	for obj in objs:
		if query_range.has_point(obj.position):
			found_objs.append(obj)
			
	if divided:
		northeast.query(query_range, found_objs)
		northwest.query(query_range, found_objs)
		southeast.query(query_range, found_objs)
		southwest.query(query_range, found_objs)
	
#将子节点合并至本节点
func merge():
	if not divided:
		return
		
	#检查所有子节点都是叶子节点
	if northeast.divided or northwest.divided or southeast.divided or southwest.divided:
		return
	
	#检查本节点及所有子节点所储存的对象总数小于容量
	if objs.size() +northeast.objs.size() +northwest.objs.size() +southeast.objs.size() +southwest.objs.size() >capacity:
		return
		
	#将子节点中的对象合并至本节点
	objs += northeast.objs
	objs += northwest.objs
	objs += southeast.objs
	objs += southwest.objs
	
	northeast = null
	northwest = null
	southeast = null
	southwest = null
	divided = false
	
