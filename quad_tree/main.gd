extends Node2D

var qt:QuadTree
var found_objs = []
var colors = {
	0:Color("f0f2e4"),
	1:Color("f5d6d6"),
	2:Color("b0f1c6"),
	3:Color("24acf2"),
	4:Color("f9d987"),
}

func _ready() -> void:
	var boundry = Rect2(Vector2(0,0),Vector2(400,400))
	qt = QuadTree.new(boundry, 2)
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		found_objs = []
		if event.button_index == MOUSE_BUTTON_LEFT:
			var obj = QuadTreeObj.new()
			obj.position = event.global_position
			qt.insert(obj)
			queue_redraw()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			var query_point = event.global_position
			var range = Rect2(query_point - Vector2(50,50),Vector2(100,100))
			
			qt.query(range, found_objs)
			queue_redraw()
			
func draw_quad_tree(tree: QuadTree, depth:int=0):
	draw_rect(tree.boundry.grow(-2), colors[depth], true)
	if tree.divided:
		draw_quad_tree(tree.northeast, depth + 1)
		draw_quad_tree(tree.northwest, depth + 1)
		draw_quad_tree(tree.southeast, depth + 1)
		draw_quad_tree(tree.southwest, depth + 1)
		
	for obj in tree.objs:
		draw_circle(obj.position, 4, Color.MEDIUM_VIOLET_RED)
			
func _draw() -> void:
	draw_quad_tree(qt)
	for obj in found_objs:
		draw_circle(obj.position, 5, Color.YELLOW)
