extends Boid
class_name BetaBoid





func _ready() -> void:
	add_to_group("Beta")
	max_speed = 200
	perception_radius = 50
	separation_limit = 40
	prey_limit = 130
	
	velocity = Vector2(randf() * max_speed, randf() * max_speed)
	rotation = velocity.angle()
	space_state = get_world_2d().direct_space_state
	
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "scale", Vector2(1, 1), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)



func _process(delta: float) -> void:
	pass
