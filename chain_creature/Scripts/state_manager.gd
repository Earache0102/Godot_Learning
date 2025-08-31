extends Node2D
class_name State_Manager

var current_state : State
var states = {}
var chain : Chain

func _init(chain : Chain) -> void:
	self.chain = chain
	#初始化states字典
	states["Wander_State"] = Wander_State.new()
	states["Food_State"] = Food_State.new()
	for state in states.values():
		get_tree().current_scene.add_child(state)
	current_state = Wander_State.new()
	
	
func change_state(target_state : State):
	current_state = target_state
